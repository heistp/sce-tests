// SPDX-License-Identifier: GPL-3.0
// Copyright 2023 Pete Heist

// This Antler package tests Some Congestion Experienced.
// https://github.com/chromi/sce

package sce

Run: {
	Serial: [
		// oneflow tests
		for c in ["reno-sce", "cubic-sce", "dctcp-sce", "cubic"]
		for r in [1, 10, 100] {
			_oneflow & {
				_rate:  100
				_rtt:   r
				_cca:   c
				_qdisc: "deltic_polya"
			}
		},

		// ratedrop tests
		for c in ["reno-sce", "cubic-sce", "dctcp-sce", "cubic"]
		for r in [1, 10, 100] {
			_ratedrop & {
				_rate0: 100
				_rate1: 10
				_rtt:   r
				_cca:   c
				_qdisc: "deltic_polya"
			}
		},

		// twoflow tests
		for c in ["reno-sce", "cubic-sce", "dctcp-sce", "cubic"]
		for r in [10] {
			_twoflow & {
				_rate:  100
				_rtt1:  r
				_rtt2:  r * 2
				_cca1:  c
				_cca2:  c
				_qdisc: "deltic_polya"
			}
		},
	]
}
