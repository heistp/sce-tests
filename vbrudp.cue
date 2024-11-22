// SPDX-License-Identifier: GPL-3.0
// Copyright 2024 Pete Heist

package sce

import "list"

// _vbrudp tests bursty, variable bitrate UDP traffic together with a TCP flow.
_vbrudp: {
	// variables
	_name:     string & !=""
	_rate:     int
	_rtt:      int
	_cca:      string & !=""
	_duration: int
	_qdisc:    string & !=""

	ID: {
		name:  _name
		rate:  "\(_rate)mbit"
		rtt:   "\(_rtt)ms"
		cca:   _cca
		qdisc: _qdisc
	}
	Path: "{{.name}}/{{.rate}}_{{.rtt}}_{{.cca}}_{{.qdisc}}_"
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
				title: "Single Flow w/ Bursty UDP, \(FlowLabel[_cca]), \(_rate)Mbps, \(_rtt)ms RTT, \(_qdisc)"
				series: {
					"0": {
						color: _dark2[0]
					}
					"1": {
						targetAxisIndex: 1
						color:           _dark2[1]
					}
					"2": {
						targetAxisIndex: 1
						color:           _dark2[2]
						lineWidth:       0
						pointSize:       0.2
					}
				}
				vAxes: {
					"0": {
						title: "Delivery Rate (Mbps)"
						viewWindow: max: _rate * 1.1
					}
					"1": {
						title: "TCP RTT / OWD (ms)"
						viewWindow: max: 1000
						scaleType: "log"
					}
				}
			}
		}},
	]

	// rig defines the dumbbell Test setup
	_rig: _dumbbell & {
		serverAddr: "\(right.addr):777"
		htbQuantum: int | *1514
		ecnValue:   int | *1
		if _cca == "bbr" {
			ecnValue: 0
		}
		left: post: list.Concat([
			_modprobe_cca,
			[
				"sysctl -w net.ipv4.tcp_ecn=\(ecnValue)",
				"sysctl -w net.ipv4.tcp_wmem=\"4096 131072 160000000\"",
			],
		])
		mid: post: [
			for c in {_addQdisc & {
				iface: "mid.r"
				qdisc: _qdisc
				rate:  "\(_rate)mbit"
			}}.Commands {c},
			"tc qdisc add dev mid.l root netem delay \(_rtt/2)ms limit 1000000",
			"ip link add dev imid.l type ifb",
			"tc qdisc add dev imid.l root handle 1: netem delay \(_rtt/2)ms limit 1000000",
			"tc qdisc add dev mid.l handle ffff: ingress",
			"ip link set dev imid.l up",
			"tc filter add dev mid.l parent ffff: protocol all prio 10 u32 match u32 0 0 flowid 1:1 action mirred egress redirect dev imid.l",
		]
		right: post: [
			"sysctl -w net.ipv4.tcp_sce=1",
			"sysctl -w net.ipv4.tcp_rmem=\"4096 131072 240000000\"",
		]
	}

	// server runs the server and captures packets on the right node
	_server: {
		Child: {
			Node: _rig.right.node
			Serial: [
				_tcpdump & {_iface:         "right.l"},
				{StreamServer: {ListenAddr: _rig.serverAddr}},
				{PacketServer: {ListenAddr: _rig.serverAddr}},
				{Sleep:                     "1s"},
			]
		}
	}

	// client runs the client and captures packets on the left node
	_client: {
		Child: {
			Node: _rig.left.node
			Serial: [
				_tcpdump & {_iface: "left.r"},
				{Sleep:             "1s"},
				{Parallel: [
					{StreamClient: {
						Addr: _rig.serverAddr
						Upload: {
							Flow:            _cca
							CCA:             _cca
							Duration:        "\(_duration)s"
							TCPInfoInterval: _tcpInfoInterval
						}
					}},
					{Serial: [
						{Sleep: "\(div(_duration, 3))s"},
						{PacketClient: {
							Addr: _rig.serverAddr
							Flow: "udp"
							Sender: [
								{Unresponsive: {
									Wait: ["10ms"]
									Length: [160]
									Duration: "\(div(_duration, 3))s"
								}},
								{Unresponsive: {
									Wait: ["0ms", "0ms", "0ms", "0ms",
										"0ms", "0ms", "0ms", "50ms"]
									Length: [900]
									Duration: "\(div(_duration, 3))s"
								}},
							]
						}},
					]},
				]},
			]
		}
	}
}
