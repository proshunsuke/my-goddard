set output "average-compare.eps"
set terminal postscript eps enhanced color size 3.5,2.5 font 'Helvetica,18'
set xl "Node number"
set yl "Throughput(bps)"
plot "average.tr" using 1:2 with lines linewidth 3 lt 1 lc 1 title "average",\
"average-no-roll.tr" using 1:2 with lines linewidth 3 lt 1 lc 2 title "average-no-role"