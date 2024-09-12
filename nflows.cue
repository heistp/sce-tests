// SPDX-License-Identifier: GPL-3.0
// Copyright 2024 Pete Heist

package sce

import "strings"

import "list"

// _nflows tests multiple flows with the given CCAs and RTT in competition.
_nflows: {
	// variables
	_name: string & !=""
	_rate: int
	_rtt:  int
	_cca: [...string]
	_flows:    int
	_duration: int
	_qdisc:    string & !=""

	ID: {
		name:  _name
		rate:  "\(_rate)mbit"
		cca:   strings.Join(_cca, "_")
		flows: "\(_flows)"
		rtt:   "\(_rtt)ms"
		qdisc: _qdisc
	}
	Path: "{{.name}}/{{.rate}}_{{.rtt}}_{{.cca}}_{{.flows}}flows_{{.qdisc}}_"
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
			_ccaList:  strings.Join(_cca, ",")
			Options: {
				title: "\(_flows) Flows, \(_rate)Mbps, CCAs:\(_ccaList), \(_rtt)ms RTT, \(_qdisc)"
				series: {
					for i in list.Range(1, _flows*2, 2) {
						"\(i)": targetAxisIndex: 1
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
		leaf:       _modprobe_cca + [
				"sysctl -w net.ipv4.tcp_wmem=\"4096 131072 160000000\"",
		]
		leaf1: post: [
				"sysctl -w net.ipv4.tcp_ecn=0",
		] + leaf
		leaf2: post: [
				"sysctl -w net.ipv4.tcp_ecn=1",
		] + leaf
		limb1: post: [
			"tc qdisc add dev limb1.r root netem delay \(_rtt)ms limit 1000000",
		]
		limb2: post: [
			"tc qdisc add dev limb2.r root netem delay \(_rtt)ms limit 1000000",
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
				Parallel: [
					for i in list.Range(0, _flows, 1)
					let cca = _cca[mod(i, len(_cca))]
					if cca == "bbr" {
						StreamClient: {
							Addr: _rig.serverAddr
							Upload: {
								Flow:            "\(cca)-\(i)"
								CCA:             cca
								Duration:        "\(_duration)s"
								TCPInfoInterval: "1s"
							}
						}
					},
				]
			}},
			{Child: {
				Node: _rig.leaf2.node
				Parallel: [
					for i in list.Range(0, _flows, 1)
					let cca = _cca[mod(i, len(_cca))]
					if cca != "bbr" {
						StreamClient: {
							Addr: _rig.serverAddr
							Upload: {
								Flow:            "\(cca)-\(i)"
								CCA:             cca
								Duration:        "\(_duration)s"
								TCPInfoInterval: "1s"
							}
						}
					},
				]
			}},
		]
	}
}
