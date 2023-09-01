// SPDX-License-Identifier: GPL-3.0
// Copyright 2023 Pete Heist

// This Antler package tests Some Congestion Experienced.
// https://github.com/chromi/sce

package sce

Run: {
	Serial: [
		for r in [1, 10, 100] {_oneflow & {
			_bandwidth: 100
			_rtt:       r
			_cca:       "cubic-sce"
			_qdisc:     "deltic"
		}},
	]
}

Results: {
	Destructive: false
}
