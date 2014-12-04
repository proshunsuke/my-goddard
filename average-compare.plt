set output "average-compare.eps"
set terminal postscript eps enhanced color size 3.5,2.5 font 'Helvetica,18'
set xl "Number of nodes"
set yl "Throughput[bps]"
plot "average.tr" using 1:2 with lines linewidth 3 title "average",\
"average-no-roll.tr" using 1:2 with lines linewidth 3 title "average-no-role"