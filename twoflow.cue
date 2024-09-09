// SPDX-License-Identifier: GPL-3.0
// Copyright 2024 Pete Heist

package sce

// _twoflow tests two flow competition, varying each flow's CCA and RTT.
_twoflow: {
	// variables
	_name:     string & !=""
	_rate:     int
	_rtt1:     int
	_rtt2:     int
	_cca1:     string & !=""
	_cca2:     string & !=""
	_duration: int
	_qdisc:    string & !=""

	ID: {
		name:  _name
		rate:  "\(_rate)mbit"
		cca1:  _cca1
		rtt1:  "\(_rtt1)ms"
		cca2:  _cca2
		rtt2:  "\(_rtt2)ms"
		qdisc: _qdisc
	}
	Path: "{{.name}}/{{.rate}}_{{.cca1}}_{{.rtt1}}_{{.cca2}}_{{.rtt2}}_{{.qdisc}}_"
	Serial: [
		_rig.setup,
		_server,
		_client,
	]

	// After lists the report stages to run after Test
	After: [
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
					"0": {
						color: _dark2[0]
					}
					"1": {
						targetAxisIndex: 1
						color:           _dark2[1]
					}
					"2": {
						color: _dark2[2]
					}
					"3": {
						targetAxisIndex: 1
						color:           _dark2[3]
					}
				}
				vAxes: {
					"0": {
						title: "Delivery Rate (Mbps)"
						viewWindow: max: _rate * 1.1
					}
					"1": {
						title: "TCP RTT (ms)"
						viewWindow: max: 1000
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
		ecnValue1:  int | *1
		if _cca1 == "bbr" {
			ecnValue1: 0
		}
		ecnValue2: int | *1
		if _cca2 == "bbr" {
			ecnValue2: 0
		}
		leaf: _modprobe_cca + [
			"sysctl -w net.ipv4.tcp_wmem=\"4096 131072 160000000\"",
		]
		leaf1: post: [
				"sysctl -w net.ipv4.tcp_ecn=\(ecnValue1)",
		] + leaf
		leaf2: post: [
				"sysctl -w net.ipv4.tcp_ecn=\(ecnValue2)",
		] + leaf
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
			"sysctl -w net.ipv4.tcp_rmem=\"4096 131072 240000000\"",
		]
	}

	// _server runs the server and captures packets on the trunk node
	_server: {
		Child: {
			Node: _rig.trunk.node
			Serial: [
				_tcpdump & {_iface:         "trunk.l"},
				{StreamServer: {ListenAddr: _rig.serverAddr}},
				{Sleep:                     "1s"},
			]
		}
	}

	// client runs the clients and captures packets on the leaf nodes
	_client: {
		Parallel: [
			{Child: {
				Node: _rig.leaf1.node
				{StreamClient: {
					Addr: _rig.serverAddr
					Upload: {
						Flow:            "\(_cca1)-1"
						CCA:             _cca1
						Duration:        "\(_duration)s"
						TCPInfoInterval: _tcpInfoInterval
					}
				}}
			}},
			{Child: {
				Node: _rig.leaf2.node
				Serial: [
					{Sleep: "\(_duration/2)s"},
					{StreamClient: {
						Addr: _rig.serverAddr
						Upload: {
							Flow:            "\(_cca2)-2"
							CCA:             _cca2
							Duration:        "\(_duration/2)s"
							TCPInfoInterval: _tcpInfoInterval
						}
					}},
				]
			}},
		]
	}
}
