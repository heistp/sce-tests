// SPDX-License-Identifier: GPL-3.0
// Copyright 2023 Pete Heist

package sce

import "list"

// _ratedrop tests one TCP flow through a drop then rise in bottleneck capacity.
_ratedrop: {
	// parameters
	_name:      string & !=""
	_rate0:     int
	_rate1:     int
	_rtt:       int
	_cca:       string & !=""
	_qdisc:     string & !=""
	_duration:  int
	_rootQdisc: list.Contains(_rootQdiscs, _qdisc)

	ID: {
		name:  _name
		rate0: "\(_rate0)mbit"
		rate1: "\(_rate1)mbit"
		rtt:   "\(_rtt)ms"
		cca:   _cca
		qdisc: _qdisc
	}
	Path: "{{.name}}/{{.rate0}}_{{.rate1}}_{{.rtt}}_{{.cca}}_{{.qdisc}}_"
	Serial: [
		_rig.setup,
		_server,
		_do,
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
				title: "Rate Drop, \(_rate0)Mbps → \(_rate1)Mbps, \(_rtt)ms RTT, \(FlowLabel[_cca]), \(_qdisc)"
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
				}
				vAxes: {
					"0": viewWindow: {
						max: _rate0 * 1.1
					}
					"1": {
						viewWindow: {
							max: 2000
						}
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
				rate:  "\(_rate0)mbit"
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

	// do defines the parallel Runners for the left (client) and mid (middlebox)
	// nodes.
	_do: {
		Parallel: [
			{Child: {
				Node:   _rig.left.node
				Serial: _left
			}},
			{Child: {
				Node:   _rig.mid.node
				Serial: _mid
			}},
		]

		// left lists the serial Runners run on the left (client) node.
		_left: [
			_tcpdump & {_iface: "left.r"},
			{Sleep:             "1s"},
			{StreamClient: {
				Addr: _rig.serverAddr
				Upload: {
					Flow:            _cca
					CCA:             _cca
					Duration:        "\(_duration)s"
					TCPInfoInterval: _tcpInfoInterval
				}
			}},
			{Sleep: "1s"},
		]

		// mid lists the serial Runners run on the mid (middlebox) node.
		_mid: [
			{Sleep: "\(div(_duration, 3))s"},
			if _rootQdisc {
				{System: Command: "tc-sce qdisc change dev mid.r root \(_qdisc) bandwidth \(_rate1)mbit"}
			},
			if !_rootQdisc {
				{System: Command: "tc class change dev mid.r parent 1: classid 1:1 htb rate \(_rate1)mbit quantum \(_rig.htbQuantum)"}
			},
			{Sleep: "\(div(_duration, 3))s"},
			if _rootQdisc {
				{System: Command: "tc-sce qdisc change dev mid.r root \(_qdisc) bandwidth \(_rate0)mbit"}
			},
			if !_rootQdisc {
				{System: Command: "tc class change dev mid.r parent 1: classid 1:1 htb rate \(_rate0)mbit quantum \(_rig.htbQuantum)"}
			},
		]
	}
}
