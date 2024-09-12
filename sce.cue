// SPDX-License-Identifier: GPL-3.0
// Copyright 2024 Pete Heist

// This Antler package tests Some Congestion Experienced.
// https://github.com/chromi/sce

package sce

Test: [
	// polya oneflow tests
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

	// polya ratedrop tests
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

	// polya twoflow tests (same RTT)
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

	// polya twoflow-rtt tests (different RTTs)
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

	// polya vbrudp tests
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

	// polya slotting tests
	for c in [ "cubic", "cubic-sce", "reno-sce", "bbr"]
	for r in [100, 1000]
	for t in [10, 80]
	for s in ["wifi", "docsis"] {
		_slotting & {
			_name:     "polya-slotting"
			_rate:     r
			_rtt:      t
			_cca:      c
			_slot:     s
			_duration: int | *(2 * 60)
			if t > 80 {
				_duration: 5 * 60
			}
			_qdisc: "deltic_polya"
		}
	},

	// polya fct tests
	for c in [
		["bbr", "bbr"],
		["bbr", "cubic"],
		["cubic", "cubic"],
		["cubic", "bbr"],
		["cubic-sce", "cubic-sce"],
		["reno-sce", "reno-sce"],
	]
	for r in [100]
	for t in [10, 80] {
		_fct & {
			_name:   "polya-fct"
			_rate:   r
			_rtt:    t
			_cca_bg: c[0]
			_cca:    c[1]
			_qdisc:  "deltic_polya"
		}
	},

	// nflows tests
	for c in [
		["bbr", "cubic", "reno"],
		["reno-sce", "cubic-sce"],
	]
	for r in [100]
	for t in [5, 10]
	for f in [8, 32, 64] {
		_nflows & {
			_name:     "polya-nflows"
			_rate:     r
			_rtt:      t
			_cca:      c
			_flows:    f
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
