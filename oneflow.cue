// SPDX-License-Identifier: GPL-3.0
// Copyright 2023 Pete Heist

package sce

// _oneflow tests one TCP flow for a given bandwidth, RTT, CCA and qdisc.
_oneflow: {
	_bandwidth: int
	_rtt:       int
	_cca:       string & !=""
	_qdisc:     string & !=""

	_duration: 60 * 6

	Test: {
		ID: {
			name:      "oneflow"
			bandwidth: "\(_bandwidth)mbit"
			rtt:       "\(_rtt)ms"
			cca:       _cca
			qdisc:     _qdisc
		}
		ResultPrefix: "{{.name}}/{{.bandwidth}}_{{.rtt}}_{{.cca}}_{{.qdisc}}_"
		Serial: [
			_rig.setup,
			_server,
			_client,
		]
	}

	Report: [
		{Analyze: {}},
		{Encode: {
			File: ["*.pcap"]
			Extension: ".zstd"
			Destructive: true
		}},
		{ChartsTimeSeries: {
			To: ["timeseries.html"]
			FlowLabel: {
				"cubic":     "CUBIC"
				"cubic-sce": "CUBIC-SCE"
				"dctcp-sce": "DCTCP-SCE"
				"reno-sce":  "Reno-SCE"
				"udp":       "UDP OWD"
			}
			Options: {
				title: "Single Flow, \(_bandwidth)Mbps, \(_rtt)ms RTT, \(FlowLabel[_cca]), \(_qdisc) "
				series: {
					"1": {
						targetAxisIndex: 1
						lineWidth:       0
						pointSize:       0.2
						color:           "#4f9634"
					}
				}
				vAxes: {
					"0": viewWindow: {
						max: _bandwidth * 1.1
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

	_rig: _dumbbell & {
		serverAddr: "10.0.0.2:777"
		left: post: [
			"modprobe tcp_cubic_sce",
			"sysctl -w net.ipv4.tcp_ecn=1",
		]
		mid: post: [
			"tc qdisc add dev mid.r root handle 1: htb default 1",
			"tc class add dev mid.r parent 1: classid 1:1 htb rate \(_bandwidth)mbit quantum 1514",
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
		]
	}

	_server: {
		Child: {
			Node: _rig.right.node
			Serial: [
				{System: {
					Command:    "tcpdump -i right.l -s 128 -w -"
					Background: true
					Stdout:     "right.pcap"
				}},
				{StreamServer: {ListenAddr: _rig.serverAddr}},
				{PacketServer: {ListenAddr: _rig.serverAddr}},
				{Sleep:                     "1s"},
			]
		}
	}

	_client: {
		Child: {
			Node: _rig.left.node
			Serial: [
				{System: {
					Command:    "tcpdump -i left.r -s 128 -w -"
					Background: true
					Stdout:     "left.pcap"
				}},
				{Sleep: "1s"},
				{Parallel: [
					{PacketClient: {
						Addr: _rig.serverAddr
						Flow: "udp"
						Sender: [
							{Unresponsive: {
								Wait: ["20ms"]
								Length: [160]
								Duration: "\(_duration)s"
							}},
						]
					}},
					{StreamClient: {
						Addr: _rig.serverAddr
						Upload: {
							Flow:             _cca
							CCA:              _cca
							Duration:         "\(_duration)s"
							IOSampleInterval: "\(_rtt*4)ms"
						}
					}},
				]},
			]
		}
	}
}
