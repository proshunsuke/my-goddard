set output "average-compare-bw.eps"
set terminal postscript eps enhanced color size 3.5,2.5 font 'Helvetica,18'
set xl "Number of nodes"
set yl "Throughput[kbps]"
plot "average-bw-low.tr" using 1:2 with lines linewidth 3 title "bandWidth:low",\
"average-bw-high.tr" using 1:2 with lines linewidth 3 title "bandWidth:high"
