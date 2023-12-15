// SPDX-License-Identifier: GPL-3.0
// Copyright 2023 Pete Heist

package sce

// _twoflow tests two flow competition, varying each flow's CCA and RTT.
_twoflow: {
	// variables
	_rate:  int
	_rtt1:  int
	_rtt2:  int
	_cca1:  string & !=""
	_cca2:  string & !=""
	_qdisc: string & !=""

	// constants
	_duration: 60

	// Test is the twoflow_cca test
	Test: {
		ID: {
			name:  "twoflow"
			rate:  "\(_rate)mbit"
			cca1:  _cca1
			rtt1:  "\(_rtt1)ms"
			cca2:  _cca2
			rtt2:  "\(_rtt2)ms"
			qdisc: _qdisc
		}
		ResultPrefix: "{{.name}}/{{.rate}}_{{.cca1}}_{{.rtt1}}_{{.cca2}}_{{.rtt2}}_{{.qdisc}}_"
		Serial: [
			_rig.setup,
			_server,
			_client,
		]
	}

	// Report lists the report stages to run after Test
	Report: [
		{Analyze: {}},
		{Encode: {
			File: ["*.pcap"]
			Extension:   ".xz"
			Destructive: true
		}},
		{ChartsTimeSeries: {
			To: ["timeseries.html"]
			FlowLabel: _flowLabel
			Options: {
				title: "Two Flow, \(_rate)Mbps, \(FlowLabel[_cca1])@\(_rtt1)ms, \(FlowLabel[_cca2])@\(_rtt2)ms, \(_qdisc)"
				series: {
					"2": {
						targetAxisIndex: 1
						lineWidth:       0
						pointSize:       0.2
					}
					"3": {
						targetAxisIndex: 1
						lineWidth:       0
						pointSize:       0.2
					}
				}
				vAxes: {
					"0": viewWindow: {
						max: _rate * 1.1
					}
					"1": {
						viewWindow: {
							max: 1000
						}
						scaleType: "log"
					}
				}
			}
		}},
	]

	// rig defines the dumbbell Test setup
	_rig: _tree2 & {
		serverAddr: "\(trunk.addr):777"
		htbQuantum: int | *1514
		leaf: [
			"modprobe tcp_cubic_sce",
			"modprobe tcp_reno_sce",
			"modprobe tcp_dctcp_sce",
			"sysctl -w net.ipv4.tcp_ecn=1",
		]
		leaf1: post: leaf
		leaf2: post: leaf
		limb1: post: [
			"tc qdisc add dev limb1.r root netem delay \(_rtt1)ms limit 1000000",
		]
		limb2: post: [
			"tc qdisc add dev limb2.r root netem delay \(_rtt2)ms limit 1000000",
		]
		fork: post: [
			"tc qdisc add dev fork.r root handle 1: htb default 1",
			"tc class add dev fork.r parent 1: classid 1:1 htb rate \(_rate)mbit quantum \(htbQuantum)",
			"tc qdisc add dev fork.r parent 1:1 \(_qdisc)",
		]
		trunk: post: [
			"sysctl -w net.ipv4.tcp_sce=1",
		]
	}

	// _server runs the server and captures packets on the trunk node
	_server: {
		Child: {
			Node: _rig.trunk.node
			Serial: [
				_tcpdump & {_iface:         "trunk.l"},
				{StreamServer: {ListenAddr: _rig.serverAddr}},
				{PacketServer: {ListenAddr: _rig.serverAddr}},
				{Sleep:                     "1s"},
			]
		}
	}

	// client runs the clients and captures packets on the leaf nodes
	_client: {
		_run1: {
			{Parallel: [
				{PacketClient: {
					Addr: _rig.serverAddr
					Flow: "udp-1"
					Sender: [
						{Unresponsive: {
							Wait: ["20ms"]
							Length: [0]
							Duration: "\(_duration)s"
						}},
					]
				}},
				{StreamClient: {
					Addr: _rig.serverAddr
					Upload: {
						Flow:             "\(_cca1)-1"
						CCA:              _cca1
						Duration:         "\(_duration)s"
						IOSampleInterval: "\(_rtt1*4)ms"
					}
				}},
			]}
		}
		_run2: {
			{Parallel: [
				{PacketClient: {
					Addr: _rig.serverAddr
					Flow: "udp-2"
					Sender: [
						{Unresponsive: {
							Wait: ["20ms"]
							Length: [0]
							Duration: "\(_duration/2)s"
						}},
					]
				}},
				{StreamClient: {
					Addr: _rig.serverAddr
					Upload: {
						Flow:             "\(_cca2)-2"
						CCA:              _cca2
						Duration:         "\(_duration/2)s"
						IOSampleInterval: "\(_rtt2*4)ms"
					}
				}},
			]}
		}
		Parallel: [
			{Child: {
				Node: _rig.leaf1.node
				_run1
			}},
			{Child: {
				Node: _rig.leaf2.node
				Serial: [
					{Sleep: "\(_duration/2)s"},
					_run2,
				]
			}},
		]
	}
}
