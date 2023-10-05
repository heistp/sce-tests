// SPDX-License-Identifier: GPL-3.0
// Copyright 2023 Pete Heist

package sce

// _platform sets the node platform used for all tests (must match the local
// machine).
_platform: "linux-amd64"

// _streamConfig selects what is streamed from nodes during tests.
_streamConfig: {ResultStream: Include: Log: true}

// _noOffloads contains the features arguments for ethtool to disable offloads
_noOffloads: "rx off tx off sg off tso off gso off gro off rxvlan off txvlan off"

// _netnsNode defines common fields for a netns node.
_netnsNode: {
	ID:       string & !=""
	Platform: _platform
	Launcher: Local: {}
	Netns: {Create: true}
}

// _dumbbell defines setup commands for a standard three-node dumbbell, with
// nodes left, mid and right.
_dumbbell: {
	setup: {
		Serial: [
			_streamConfig,
			for n in [ right, mid, left] {
				Child: {
					Node: n.node
					Serial: [
						_streamConfig,
						for c in n.setup {System: Command: c},
					]
				}
			},
		]
	}

	right: {
		post: [...string]
		node:  _netnsNode & {ID: "right"}
		addr:  "10.0.0.2"
		setup: [
			"sysctl -w net.ipv6.conf.all.disable_ipv6=1",
			"ip link add dev right.l type veth peer name mid.r",
			"ip link set dev mid.r netns mid",
			"ip addr add \(addr)/24 dev right.l",
			"ip link set right.l up",
			"ethtool -K right.l \(_noOffloads)",
		] + post
	}

	mid: {
		post: [...string]
		node:  _netnsNode & {ID: "mid"}
		setup: [
			"sysctl -w net.ipv6.conf.all.disable_ipv6=1",
			"ip link set mid.r up",
			"ip link add dev mid.l type veth peer name left.r",
			"ip link set dev left.r netns left",
			"ip link set dev mid.l up",
			"ip link add name mid.b type bridge",
			"ip link set dev mid.r master mid.b",
			"ip link set dev mid.l master mid.b",
			"ip link set dev mid.b up",
			"ethtool -K mid.r \(_noOffloads)",
			"ethtool -K mid.l \(_noOffloads)",
		] + post
	}

	left: {
		post: [...string]
		node:  _netnsNode & {ID: "left"}
		addr:  "10.0.0.1"
		setup: [
			"sysctl -w net.ipv6.conf.all.disable_ipv6=1",
			"ip addr add \(addr)/24 dev left.r",
			"ip link set left.r up",
			"ping -c 3 -i 0.1 \(_dumbbell.right.addr)",
			"ethtool -K left.r \(_noOffloads)",
		] + post
	}
}
