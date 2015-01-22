set output "average-compare-gat.eps"
set terminal postscript eps enhanced color size 3.5,2.5 font 'Helvetica,18'
set xl "Number of nodes"
set yl "Throughput[kbps]"
plot "average-gat-0.1.tr" using 1:2 with lines linewidth 3 title "gateNode:10%, semiGateNode:20%",\
"average-gat-0.2.tr" using 1:2 with lines linewidth 3 title "gateNode:20%, semiGateNode:40%"