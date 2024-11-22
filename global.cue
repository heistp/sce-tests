// SPDX-License-Identifier: GPL-3.0
// Copyright 2024 Pete Heist

package sce

// _flowLabel defines common labels for flows.
_flowLabel: {
	"bbr":       string & !="" | *"BBR"
	"cubic":     string & !="" | *"CUBIC"
	"cubic-sce": string & !="" | *"CUBIC-SCE"
	"dctcp":     string & !="" | *"DCTCP"
	"dctcp-sce": string & !="" | *"DCTCP-SCE"
	"reno":      string & !="" | *"Reno"
	"reno-sce":  string & !="" | *"Reno-SCE"
	"udp":       string & !="" | *"UDP"
}

// _dark2 is the Dark2 qualitative color scheme from colorbrewer2.org, with
// the first blue-green color replaced by the green color, as it's too close.
_dark2: [
	//"#1b9e77",
	"#66a61e",
	"#d95f02",
	"#7570b3",
	"#e7298a",
	"#e6ab02",
	"#a6761d",
	"#666666",
]

// _tcpdump defines a Runner to run tcpdump to stdout, and save stdout to a file.
_tcpdump: {
	// iface defines the interface to capture on.
	_iface: string & !=""

	// snaplen is how many bytes to capture from each packet.
	_snaplen: int | *128

	System: {
		Command:    "tcpdump -i \(_iface) -s \(_snaplen) -w -"
		Background: true
		Stdout:     "\(_iface).pcap"
	}
}

// _modprobe_cca defines the modprobe commands for each CCA.
_modprobe_cca: [
	"modprobe tcp_cubic_sce",
	"modprobe tcp_dctcp_sce",
	"modprobe tcp_reno_sce",
	"modprobe tcp_bbr",
]

// _tcpInfoInterval is the default sample interval for TCP info from sock_diag.
_tcpInfoInterval: "20ms"

#Results: Codec: xz: EncodeArg: ["-0"]
