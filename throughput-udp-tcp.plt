set output "throughput-udp-tcp.eps"
set terminal postscript eps enhanced color size 3.5,2.5 font 'Helvetica,18'
set xl "Secons"
set yl "Throughput(bps) "
plot "tput-udp200.tr" using 1:2 with lines linewidth 3 lt 1 lc 1 title "udp200",\
"tput-udp400.tr" using 1:2 with lines linewidth 3 lt 1 lc 2 title "udp400",\
"tput-udp600.tr" using 1:2 with lines linewidth 3 lt 1 lc 3 title "udp600",\
"tput-udp800.tr" using 1:2 with lines linewidth 3 lt 1 lc 4 title "udp800",\
"tput-tcp200.tr" using 1:2 with lines linewidth 3 lt 1 lc 5 title "tcp200",\
"tput-tcp400.tr" using 1:2 with lines linewidth 3 lt 1 lc 6 title "tcp400",\
"tput-tcp600.tr" using 1:2 with lines linewidth 3 lt 1 lc 7 title "tcp600",\
"tput-tcp800.tr" using 1:2 with lines linewidth 3 lt 1 lc 8 title "tcp800"



