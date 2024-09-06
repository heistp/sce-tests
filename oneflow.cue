// SPDX-License-Identifier: GPL-3.0
// Copyright 2024 Pete Heist

package sce

// _oneflow tests one TCP flow for a given rate, RTT, CCA and qdisc.
_oneflow: {
	// variables
	_name:     string & !=""
	_rate:     int
	_rtt:      int
	_cca:      string & !=""
	_qdisc:    string & !=""
	_duration: int

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
				title: "Single Flow \(FlowLabel[_cca]), \(_rate)Mbps, \(_rtt)ms RTT, \(_qdisc)"
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
		ecnValue:   int | *1
		if _cca == "bbr" {
			ecnValue: 0
		}
		left: post: [
			"modprobe tcp_cubic_sce",
			"modprobe tcp_reno_sce",
			"modprobe tcp_dctcp_sce",
			"sysctl -w net.ipv4.tcp_ecn=\(ecnValue)",
			"sysctl -w net.ipv4.tcp_wmem=\"4096 131072 160000000\"",
		]
		mid: post: [
			"tc qdisc add dev mid.r root handle 1: htb default 1",
			"tc class add dev mid.r parent 1: classid 1:1 htb rate \(_rate)mbit quantum \(htbQuantum)",
			"tc qdisc add dev mid.r parent 1:1 \(_qdisc)",
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
				{StreamClient: {
					Addr: _rig.serverAddr
					Upload: {
						Flow:            _cca
						CCA:             _cca
						Duration:        "\(_duration)s"
						TCPInfoInterval: _tcpInfoInterval
					}
				}},
			]
		}
	}
}
