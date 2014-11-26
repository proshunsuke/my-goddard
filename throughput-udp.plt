set output "throughput-udp.eps"
set terminal postscript eps enhanced color size 3.5,2.5 font 'Helvetica,18'
set xl "Secons"
set yl "Throughput(bps) "
plot "tput-udp200.tr" using 1:2 with lines linewidth 3 lt 1 lc 1 title "udp200",\
"tput-udp400.tr" using 1:2 with lines linewidth 3 lt 1 lc 2 title "udp400",\
"tput-udp600.tr" using 1:2 with lines linewidth 3 lt 1 lc 3 title "udp600",\
"tput-udp800.tr" using 1:2 with lines linewidth 3 lt 1 lc 4 title "udp800"



