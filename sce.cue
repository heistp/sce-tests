// SPDX-License-Identifier: GPL-3.0
// Copyright 2024 Pete Heist

// This Antler package tests Some Congestion Experienced.
// https://github.com/chromi/sce

package sce

Test: [
	//
	// POLYA
	//

	// polya oneflow tests (cubic-sce removed)
	for c in ["cubic", "reno-sce", "bbr"]
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

	// TODO remove below if cubic-sce not needed
	//for c in ["cubic-sce"]
	//for t in [40]
	//for r in [1, 10, 100, 1000] {
	//	_oneflow & {
	//		_name:     "polya-oneflow"
	//		_rate:     r
	//		_rtt:      t
	//		_cca:      c
	//		_duration: int | *(2 * 60)
	//		if t > 80 {
	//			_duration: 5 * 60
	//		}
	//		_qdisc: "deltic_polya"
	//	}
	//},

	// polya ratedrop tests (cubic-sce removed)
	for c in ["cubic", "reno-sce", "bbr"]
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
		//["cubic-sce", "cubic-sce"],
		["bbr", "bbr"],
		// heterogeneous
		["reno", "cubic"],
		["reno", "bbr"],
		["cubic", "bbr"],
		//["reno-sce", "cubic-sce"],
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

	// polya twoflow-rtt tests (different RTTs) (cubic-sce removed)
	for c in [ "reno", "reno-sce", "cubic", "bbr"]
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

	// polya vbrudp tests (cubic-sce removed)
	for c in [ "reno", "reno-sce", "cubic", "bbr"]
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

	// polya slotting tests (cubic-sce removed)
	for c in [ "cubic", "reno-sce", "bbr"]
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
	//for c in [
	//	["bbr", "bbr"],
	//	["bbr", "cubic"],
	//	["cubic", "cubic"],
	//	["cubic", "bbr"],
	//	["cubic-sce", "cubic-sce"],
	//	["reno-sce", "reno-sce"],
	//]
	//for r in [100]
	//for t in [10, 80] {
	//	_fct & {
	//		_name:   "polya-fct"
	//		_rate:   r
	//		_rtt:    t
	//		_cca_bg: c[0]
	//		_cca:    c[1]
	//		_qdisc:  "deltic_polya"
	//	}
	//},

	// polya nflows tests
	for c in [
		["bbr", "cubic", "reno"],
		["reno-sce"], // cubic-sce
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

	//
	// BOROSHNE
	//

	// boroshne oneflow tests (cubic-sce removed)
	for c in ["cubic", "reno-sce", "bbr"]
	for t in [1, 10, 40, 160, 320]
	for r in [1, 10, 100, 1000] {
		_oneflow & {
			_name:     "boroshne-oneflow"
			_rate:     r
			_rtt:      t
			_cca:      c
			_duration: int | *(2 * 60)
			if t > 80 {
				_duration: 5 * 60
			}
			_qdisc: "deltic_boroshne"
		}
	},

	// boroshne ratedrop tests (cubic-sce removed)
	for c in ["cubic", "reno-sce", "bbr"]
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
			_qdisc: "deltic_boroshne"
		}
	},

	// boroshne twoflow tests (same RTT)
	for c in [
		// homogenous
		["reno", "reno"],
		["reno-sce", "reno-sce"],
		["cubic", "cubic"],
		//["cubic-sce", "cubic-sce"],
		["bbr", "bbr"],
		// heterogeneous
		["reno", "cubic"],
		["reno", "bbr"],
		["cubic", "bbr"],
		["cubic", "dctcp-sce"],
		["cubic", "reno-sce"],
		//["reno-sce", "cubic-sce"],
	]
	for r in [100, 1000]
	for t in [10, 160] {
		_twoflow & {
			_name:     "boroshne-twoflow"
			_rate:     r
			_rtt1:     t
			_rtt2:     t
			_cca1:     c[0]
			_cca2:     c[1]
			_duration: int | *(2 * 60)
			if t > 80 {
				_duration: 5 * 60
			}
			_qdisc: "deltic_boroshne"
		}
	},

	// boroshne twoflow tests (same RTT)
	for c in [
		// homogenous
		["reno-sce", "reno-sce"],
		// heterogeneous
		["cubic", "dctcp-sce"],
		["cubic", "reno-sce"],
	]
	for r in [100, 1000]
	for t in [1, 10, 20, 40, 80, 160] {
		_twoflow & {
			_name:     "boroshne-twoflow-sce"
			_rate:     r
			_rtt1:     t
			_rtt2:     t
			_cca1:     c[0]
			_cca2:     c[1]
			_duration: int | *(2 * 60)
			if t > 80 {
				_duration: 5 * 60
			}
			_qdisc: "deltic_boroshne"
		}
	},

	// boroshne twoflow-rtt tests (different RTTs) (cubic-sce removed)
	for c in [ "reno", "reno-sce", "cubic", "bbr"]
	for r in [100, 1000]
	for t in [[10, 20], [20, 80], [10, 160]] {
		_twoflow & {
			_name:     "boroshne-twoflow-rtt"
			_rate:     r
			_rtt1:     t[0]
			_rtt2:     t[1]
			_cca1:     c
			_cca2:     c
			_duration: int | *(2 * 60)
			if t[1] > 80 {
				_duration: 5 * 60
			}
			_qdisc: "deltic_boroshne"
		}
	},

	// boroshne vbrudp tests (cubic-sce removed)
	for c in [ "reno", "reno-sce", "cubic", "bbr"]
	for r in [100, 1000]
	for t in [10, 160] {
		_vbrudp & {
			_name:     "boroshne-vbrudp"
			_rate:     r
			_rtt:      t
			_cca:      c
			_duration: int | *(2 * 60)
			if t > 80 {
				_duration: 5 * 60
			}
			_qdisc: "deltic_boroshne"
		}
	},

	// boroshne slotting tests
	//for c in [ "cubic", "reno-sce", "bbr"] // cubic-sce
	//for r in [100, 1000]
	//for t in [10, 80]
	//for s in ["wifi", "docsis"] {
	//	_slotting & {
	//		_name:     "boroshne-slotting"
	//		_rate:     r
	//		_rtt:      t
	//		_cca:      c
	//		_slot:     s
	//		_duration: int | *(2 * 60)
	//		if t > 80 {
	//			_duration: 5 * 60
	//		}
	//		_qdisc: "deltic_boroshne"
	//	}
	//},

	// boroshne nflows tests
	for c in [
		["bbr", "cubic", "reno"],
		["reno-sce"], // cubic-sce
	]
	for r in [100]
	for t in [5, 10]
	for f in [8, 32, 64] {
		_nflows & {
			_name:     "boroshne-nflows"
			_rate:     r
			_rtt:      t
			_cca:      c
			_flows:    f
			_duration: int | *(2 * 60)
			if t > 80 {
				_duration: 5 * 60
			}
			_qdisc: "deltic_boroshne"
		}
	},

	// mix tests
	for t in [5, 20] {
		_mix & {
			_name:     "boroshne-mix"
			_rtt:      t
			_duration: int | *(1 * 60)
			if t > 80 {
				_duration: 5 * 60
			}
			_qdisc: "deltic_boroshne"
		}
	},
]

MultiReport: [{
	Index: {
		Title:   "SCE Tests"
		GroupBy: "name"
	}
}]
