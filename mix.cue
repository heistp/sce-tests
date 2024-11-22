// SPDX-License-Identifier: GPL-3.0
// Copyright 2024 Pete Heist

package sce

import "list"

// _mix tests a mix of flows: Reno, Reno-SCE, isochronous UDP and
// unresponsive UDP.
_mix: {
	// variables
	_name:     string & !=""
	_rate:     int
	_rtt:      int
	_qdisc:    string & !=""
	_duration: int

	// constants
	_rate: 100 // tied to udp-flood interval

	ID: {
		name:  _name
		rate:  "\(_rate)mbit"
		rtt:   "\(_rtt)ms"
		qdisc: _qdisc
	}
	Path: "{{.name}}/{{.rate}}_{{.rtt}}_{{.qdisc}}_"
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
				title: "Flow Mix (Reno, Reno-SCE, isochronous UDP, unresponsive UDP), \(_rate)Mbps, \(_rtt)ms RTT, \(_qdisc)"
				series: {
					"0": {
						color:     _dark2[0]
						lineWidth: 1.5
					}
					"1": {
						targetAxisIndex: 1
						lineWidth:       0
						pointSize:       0.5
						color:           _dark2[1]
					}
					"2": {
						color:     _dark2[2]
						lineWidth: 1.5
					}
					"3": {
						targetAxisIndex: 1
						lineWidth:       0
						pointSize:       0.5
						color:           _dark2[3]
					}
					"4": {
						targetAxisIndex: 1
						lineWidth:       0
						pointSize:       0.5
						color:           _dark2[4]
					}
					"5": {
						targetAxisIndex: 1
						lineWidth:       0
						pointSize:       0.5
						color:           _dark2[5]
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
	_rig: _dumbbell & {
		serverAddr: "\(right.addr):777"
		htbQuantum: int | *1514
		left: post: list.Concat([
			_modprobe_cca,
			[
				"sysctl -w net.ipv4.tcp_ecn=1",
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
							Flow:            "reno"
							CCA:             "reno"
							Duration:        "\(_duration)s"
							TCPInfoInterval: _tcpInfoInterval
						}
					}},
					{StreamClient: {
						Addr: _rig.serverAddr
						Upload: {
							Flow:            "reno-sce"
							CCA:             "reno-sce"
							Duration:        "\(_duration)s"
							TCPInfoInterval: _tcpInfoInterval
						}
					}},
					{PacketClient: {
						Addr: _rig.serverAddr
						Flow: "udp-iso"
						Sender: [
							{Unresponsive: {
								Echo: true
								Wait: ["20ms"]
								Length: [160]
								Duration: "\(_duration)s"
							}},
						]
					}},
					{Serial: [
						{Sleep: "\(div(_duration, 3))s"},
						{PacketClient: {
							Addr: _rig.serverAddr
							Flow: "udp-flood"
							Sender: [
								{Unresponsive: {
									Wait: ["100us"]
									Length: [1472]
									Duration: "10s"
								}},
							]
						}},
					]},
				]},
			]
		}
	}
}
