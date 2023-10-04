// SPDX-License-Identifier: GPL-3.0
// Copyright 2023 Pete Heist

// This Antler package tests Some Congestion Experienced.
// https://github.com/chromi/sce

package sce

Run: {
	Serial: [
		// oneflow tests
		for c in ["reno-sce", "cubic-sce", "dctcp-sce", "cubic"]
		for r in [1, 10, 100] {_oneflow & {
			_bandwidth: 100
			_rtt:       r
			_cca:       c
			_qdisc:     "deltic"
		}},
	]
}
