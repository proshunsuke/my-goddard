file_path="/home/shunsuke/Downloads/ns2/new-ns-2.35/ns-allinone-2.35/ns-2.35/tcl/goddard/ex/my-goddard"
img_path="/home/shunsuke/Downloads/ns2/new-ns-2.35/ns-allinone-2.35/ns-2.35/tcl/goddard/ex/my-goddard/imgs"
resume_path="/home/shunsuke/sueda_lab/siryou/happyoukai/2014電子情報通信学会IN研究会/原稿/resume"
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
gnuplot-comment:
	gnuplot comment.plt
	cp comment.eps fig6.eps
	cp fig6.eps $(resume_path)
	cp fig6.eps $(img_path)
gnuplot-udp:
	gnuplot throughput-udp.plt
	cp throughput-udp.eps fig8.eps
	cp fig8.eps $(resume_path)
	cp fig8.eps $(img_path)
gnuplot-udp-tcp:
	gnuplot throughput-udp-tcp.plt
	cp throughput-udp-tcp.eps fig9.eps
	cp fig9.eps $(resume_path)
	cp fig9.eps $(img_path)
gnuplot-average:
	gnuplot average.plt
	cp average.eps fig10.eps
	cp fig10.eps $(resume_path)
	cp fig10.eps $(img_path)
gnuplot-udp-no-roll:
	gnuplot throughput-udp-no-roll.plt
	cp throughput-udp-no-roll.eps fig12.eps
	cp fig12.eps $(resume_path)
	cp fig12.eps $(img_path)
gnuplot-udp-tcp-no-roll:
	gnuplot throughput-udp-tcp-no-roll.plt
	cp throughput-udp-tcp-no-roll.eps fig13.eps
	cp fig13.eps $(resume_path)
	cp fig13.eps $(img_path)
gnuplot-average-no-roll:
	gnuplot average-no-roll.plt
	cp average-no-roll.eps fig14.eps
	cp fig14.eps $(resume_path)
	cp fig14.eps $(img_path)
gnuplot-average-compare:
	gnuplot average-compare.plt
	cp average-compare.eps fig15.eps
	cp fig15.eps $(resume_path)
	cp fig15.eps $(img_path)
gnuplot-all:
	make gnuplot-comment
	make gnuplot-udp
	make gnuplot-udp-tcp
	make gnuplot-average
	make gnuplot-udp-no-roll
	make gnuplot-udp-tcp-no-roll
	make gnuplot-average-no-roll
	make gnuplot-average-compare
