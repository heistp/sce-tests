// SPDX-License-Identifier: GPL-3.0
// Copyright 2024 Pete Heist

// This Antler package tests Some Congestion Experienced.
// https://github.com/chromi/sce

package sce

Test: [
	// oneflow tests
	for c in ["cubic", "cubic-sce", "bbr"]
	for t in [1, 10, 40, 160, 320]
	for r in [1, 10, 100, 1000] {
		_oneflow & {
			_name:     "polya-oneflow"
			_rate:     r
			_rtt:      t
			_cca:      c
			_duration: int | *(2 * 60)
			if t > 80 {
				_duration: 5 * 60
			}
			_qdisc: "deltic_polya"
		}
	},

	// ratedrop tests
	for c in ["cubic", "cubic-sce", "bbr"]
	for r in [100, 1000]
	for t in [20, 160] {
		_ratedrop & {
			_name:     "polya-ratedrop"
			_rate0:    r
			_rate1:    div(r, 10)
			_rtt:      t
			_cca:      c
			_duration: int | *(2 * 60)
			if t > 80 {
				_duration: 5 * 60
			}
			_qdisc: "deltic_polya"
		}
	},

	// twoflow tests (same RTT)
	for c in [
		// homogenous
		["reno", "reno"],
		["reno-sce", "reno-sce"],
		["cubic", "cubic"],
		["cubic-sce", "cubic-sce"],
		["bbr", "bbr"],
		// heterogeneous
		["reno", "cubic"],
		["reno", "bbr"],
		["cubic", "bbr"],
		["reno-sce", "cubic-sce"],
	]
	for r in [100, 1000]
	for t in [10, 160] {
		_twoflow & {
			_name:     "polya-twoflow"
			_rate:     r
			_rtt1:     t
			_rtt2:     t
			_cca1:     c[0]
			_cca2:     c[1]
			_duration: int | *(2 * 60)
			if t > 80 {
				_duration: 5 * 60
			}
			_qdisc: "deltic_polya"
		}
	},

	// twoflow-rtt tests (different RTTs)
	for c in [ "reno", "reno-sce", "cubic", "cubic-sce", "bbr"]
	for r in [100, 1000]
	for t in [[10, 20], [20, 80], [10, 160]] {
		_twoflow & {
			_name:     "polya-twoflow-rtt"
			_rate:     r
			_rtt1:     t[0]
			_rtt2:     t[1]
			_cca1:     c
			_cca2:     c
			_duration: int | *(2 * 60)
			if t[1] > 80 {
				_duration: 5 * 60
			}
			_qdisc: "deltic_polya"
		}
	},

	// vbrudp tests
	for c in [ "reno", "reno-sce", "cubic", "cubic-sce", "bbr"]
	for r in [100, 1000]
	for t in [10, 160] {
		_vbrudp & {
			_name:     "polya-vbrudp"
			_rate:     r
			_rtt:      t
			_cca:      c
			_duration: int | *(2 * 60)
			if t > 80 {
				_duration: 5 * 60
			}
			_qdisc: "deltic_polya"
		}
	},
]

MultiReport: [{
	Index: {
		Title:   "SCE Tests"
		GroupBy: "name"
	}
}]
