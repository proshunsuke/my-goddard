set output "average-hop-count.eps"
set terminal postscript eps enhanced color size 3.5,2.5 font 'Helvetica,18'
set xl "Number of nodes"
set yl "Average of number of hops"
set yrange [0:]
plot "average-hop-count.tr" using 1:2 with lines linewidth 3 title "average",\
"average-hop-count-no-roll.tr" using 1:2 with lines linewidth 3 title "average-no-role"