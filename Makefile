file_path="/home/shunsuke/Downloads/ns2/new-ns-2.35/ns-allinone-2.35/ns-2.35/tcl/goddard/ex/my-goddard"
ns="/home/shunsuke/Downloads/ns2/new-ns-2.35/ns-allinone-2.35/bin/ns"
my-goddard:
	cd $(file_path)
	$(ns) my-goddard.tcl $(userNum)
my-goddard-no-roll:
	cd $(file_path)
	$(ns) my-goddard-no-roll.tcl $(userNum)
nam:
	nam out.nam &
xgraph-udp:
	 xgraph -geometry 800x600 -bb -tk -m -x Seconds -y "Throughput (kbps)" tput-udp200.tr tput-udp400.tr tput-udp600.tr tput-udp800.tr &
xgraph-udp-no-roll:
	 xgraph -geometry 800x600 -bb -tk -m -x Seconds -y "Throughput (kbps)" tput-udp200-no-roll.tr tput-udp400-no-roll.tr tput-udp600-no-roll.tr tput-udp800-no-roll.tr &
xgraph-udp-tcp:
	 xgraph -geometry 800x600 -bb -tk -m -x Seconds -y "Throughput (kbps)" tput-udp200.tr tput-udp400.tr tput-udp600.tr tput-udp800.tr tput-tcp200.tr tput-tcp400.tr tput-tcp600.tr tput-tcp800.tr &
xgraph-udp-tcp-no-roll:
	 xgraph -geometry 800x600 -bb -tk -m -x Seconds -y "Throughput (kbps)" tput-udp200-no-roll.tr tput-udp400-no-roll.tr tput-udp600-no-roll.tr tput-udp800-no-roll.tr tput-tcp200-no-roll.tr tput-tcp400-no-roll.tr tput-tcp600-no-roll.tr tput-tcp800-no-roll.tr &
xgraph-comment:
	xgraph -geometry 800x600 -bb -tk -m -x "comment num" -y "ratio" comment-analysis.tr &
xgraph-average:
	xgraph -geometry 800x600 -bb -tk -m -x "Node num" -y "Throughput (kbps)" average.tr &
xgraph-average-no-roll:
	xgraph -geometry 800x600 -bb -tk -m -x "Node num" -y "Throughput (kbps)" average-no-roll.tr &
xgraph-average-compare:
	xgraph -geometry 800x600 -bb -tk -m -x "Node num" -y "Throughput (kbps)" average.tr average-no-roll.tr &
awk-average:
	awk -f throughput-udp-tcp.awk out.tr
