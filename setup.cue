// SPDX-License-Identifier: GPL-3.0
// Copyright 2023 Pete Heist

package sce

// _platform sets the node platform used for all tests (must match the local
// machine).
_platform: "linux-amd64"

// _stream selects what is streamed from nodes during tests.
_stream: {ResultStream: Include: Log: true}

// _sysinfo selects what system information is retrieved.
_sysinfo: {
	SysInfo: {
		OS: {
			Command: {Command: "uname -a"}
		}
		Command: [
			{Command: "lscpu"},
			{Command: "lshw -sanitize"},
		]
		File: [
			"/proc/cmdline",
			"/sys/devices/system/clocksource/clocksource0/available_clocksource",
			"/sys/devices/system/clocksource/clocksource0/current_clocksource",
		]
		Sysctl: [
			"^net\\.core\\.",
			"^net\\.ipv4\\.tcp_",
			"^net\\.ipv4\\.udp_",
		]
	}
}

// _noOffloads contains the features arguments for ethtool to disable offloads
_noOffloads: "rx off tx off sg off tso off gso off gro off rxvlan off txvlan off"

// _netnsNode defines common fields for a netns node.
_netnsNode: {
	ID:       string & !=""
	Platform: _platform
	Launcher: Local: {}
	Netns: {Create: true}
}

// _dumbbell defines setup commands for a three-node dumbbell, with nodes left,
// mid and right, where mid is a bridge.
//
// left <-10.0.0.0/24-> mid <-10.0.0.0/24-> right
_dumbbell: {
	setup: {
		Serial: [
			_stream,
			_sysinfo,
			for n in [ right, mid, left] {
				Child: {
					Node: n.node
					Serial: [
						_stream,
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

// _tree2 defines setup commands for a tree of nodes with two branches. There
// are six total nodes: leaf1/2, limb1/2, fork and trunk connected as follows:
//
// leaf1 <-10.0.11.0/24-> limb1 <-10.0.10.0/24->
//                                               fork <-10.0.0.0/24-> trunk
// leaf2 <-10.0.21.0/24-> limb2 <-10.0.20.0/24->
_tree2: {
	setup: {
		Serial: [
			_stream,
			for n in [ trunk, fork, limb1, leaf1, limb2, leaf2] {
				Child: {
					Node: n.node
					Serial: [
						_stream,
						for c in n.setup {System: Command: c},
					]
				}
			},
		]
	}

	trunk: {
		post: [...string]
		node:  _netnsNode & {ID: "trunk"}
		addr:  "10.0.0.2"
		setup: [
			"sysctl -w net.ipv6.conf.all.disable_ipv6=1",
			"ip link add dev trunk.l type veth peer name fork.r",
			"ip link set dev fork.r netns fork",
			"ip addr add \(addr)/24 dev trunk.l",
			"ip link set trunk.l up",
			"ethtool -K trunk.l \(_noOffloads)",
			"ip route add default via 10.0.0.1",
		] + post
	}

	fork: {
		post: [...string]
		node:  _netnsNode & {ID: "fork"}
		setup: [
			"sysctl -w net.ipv6.conf.all.disable_ipv6=1",
			"sysctl -w net.ipv4.ip_forward=1",
			"ip addr add 10.0.0.1/24 dev fork.r",
			"ip link set fork.r up",
			"ip link add dev fork.l1 type veth peer name limb1.r",
			"ip link set dev limb1.r netns limb1",
			"ip addr add 10.0.10.2/24 dev fork.l1",
			"ip link set fork.l1 up",
			"ip link add dev fork.l2 type veth peer name limb2.r",
			"ip link set dev limb2.r netns limb2",
			"ip addr add 10.0.20.2/24 dev fork.l2",
			"ip link set fork.l2 up",
			"ethtool -K fork.r \(_noOffloads)",
			"ethtool -K fork.l1 \(_noOffloads)",
			"ethtool -K fork.l2 \(_noOffloads)",
			"ip route add 10.0.11.0/24 via 10.0.10.1",
			"ip route add 10.0.21.0/24 via 10.0.20.1",
		] + post
	}

	limb1: _limb & {_n: 1}

	limb2: _limb & {_n: 2}

	_limb: {
		_n:  int // node number
		_id: "limb\(_n)"
		post: [...string]
		node:  _netnsNode & {ID: _id}
		setup: [
			"sysctl -w net.ipv6.conf.all.disable_ipv6=1",
			"sysctl -w net.ipv4.ip_forward=1",
			"ip addr add 10.0.\(_n)0.1/24 dev \(_id).r",
			"ip link set \(_id).r up",
			"ip link add dev \(_id).l type veth peer name leaf\(_n).r",
			"ip link set dev leaf\(_n).r netns leaf\(_n)",
			"ip addr add 10.0.\(_n)1.2/24 dev \(_id).l",
			"ip link set \(_id).l up",
			"ethtool -K \(_id).r \(_noOffloads)",
			"ethtool -K \(_id).l \(_noOffloads)",
			"ip route add 10.0.0.0/24 via 10.0.\(_n)0.2",
		] + post
	}

	leaf1: _leaf & {_n: 1}

	leaf2: _leaf & {_n: 2}

	_leaf: {
		_n:  int // node number
		_id: "leaf\(_n)"
		post: [...string]
		node:  _netnsNode & {ID: _id}
		setup: [
			"sysctl -w net.ipv6.conf.all.disable_ipv6=1",
			"ip addr add 10.0.\(_n)1.1/24 dev \(_id).r",
			"ip link set \(_id).r up",
			"ethtool -K \(_id).r \(_noOffloads)",
			"ip route add default via 10.0.\(_n)1.2",
			"ping -c 3 -i 0.01 \(_tree2.trunk.addr)",
		] + post
	}
}
