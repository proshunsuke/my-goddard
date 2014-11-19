my-goddard:
	ns my-goddard.tcl
my-goddard-no-roll:
	ns my-goddard-no-roll.tcl
nam:
	nam out.nam &
xgraph-udp:
	 xgraph -geometry 800x600 -bb -tk -m -x Seconds -y "Throughput (kbps)" tput-udp200.tr tput-udp400.tr tput-udp600.tr tput-udp800.tr &
xgraph-udp-tcp:
	 xgraph -geometry 800x600 -bb -tk -m -x Seconds -y "Throughput (kbps)" tput-udp200.tr tput-udp400.tr tput-udp600.tr tput-udp800.tr tput-tcp200.tr tput-tcp400.tr tput-tcp600.tr tput-tcp800.tr &

xgraph-comment:
	xgraph -geometry 800x600 -bb -tk -m -x "comment num" -y "ratio" comment-analysis.tr &
xgraph-average:
	xgraph -geometry 800x600 -bb -tk -m -x "Node num" -y "Throughput (kbps)" average.tr &
awk-average:
	awk -f throughput-udp-tcp.awk out.tr
