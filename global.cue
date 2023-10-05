// SPDX-License-Identifier: GPL-3.0
// Copyright 2023 Pete Heist

package sce

// flowLabel defines common labels for flows.
_flowLabel: {
	"cubic":     string & !="" | *"CUBIC"
	"cubic-sce": string & !="" | *"CUBIC-SCE"
	"dctcp-sce": string & !="" | *"DCTCP-SCE"
	"reno-sce":  string & !="" | *"Reno-SCE"
	"udp":       string & !="" | *"UDP OWD"
}

// tcpdump defines a Runner to run tcpdump to stdout, and save stdout to a file.
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
