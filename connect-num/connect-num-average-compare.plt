set output "connect-num-average-compare.eps"
set terminal postscript eps enhanced color size 3.5,2.5 font 'Helvetica,18'
set xl "Number of nodes"
set yl "Number of connects"
plot "connect-num-average.tr" using 1:2 with lines linewidth 3 title "average",\
"connect-num-average-no-roll.tr" using 1:2 with lines linewidth 3 title "average-no-role"