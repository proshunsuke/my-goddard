set output "connect-num-no-roll.eps"
set terminal postscript eps enhanced color size 3.5,2.5 font 'Helvetica,18'
set style histogram clustered
set style fill solid border lc rgb "black"
set xl "Number of connects"
set yl "Number of nodes"
plot "connect-num200no-roll.tr" using 2:xtic(1) with histogram title "200",\
"connect-num400no-roll.tr" using 2:xtic(1) with histogram title "400",\
"connect-num600no-roll.tr" using 2:xtic(1) with histogram title "600",\
"connect-num800no-roll.tr" using 2:xtic(1) with histogram title "800"

