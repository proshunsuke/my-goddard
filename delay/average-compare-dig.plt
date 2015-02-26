set output "average-compare-dig.eps"
set terminal postscript eps enhanced color size 3.5,2.5 font 'Helvetica,18'
set xl "Number of nodes"
set yl "Throughput[kbps]"
plot "average-dig-0.1.tr" using 1:2 with lines linewidth 3 title "digest:10%",\
"average-dig-0.2.tr" using 1:2 with lines linewidth 3 title "digest:20%",\
"average-dig-0.3.tr" using 1:2 with lines linewidth 3 title "digest:30%"