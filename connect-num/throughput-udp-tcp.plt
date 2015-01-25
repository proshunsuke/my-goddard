set output "throughput-udp-tcp.eps"
set terminal postscript eps enhanced color size 3.5,2.5 font 'Helvetica,18'
set xl "Time[sec]"
set yl "Throughput[kbps]"
plot "tput-udp200.tr" using 1:2 with lines linewidth 3 title "udp200",\
"tput-udp400.tr" using 1:2 with lines linewidth 3 title "udp400",\
"tput-udp600.tr" using 1:2 with lines linewidth 3 title "udp600",\
"tput-udp800.tr" using 1:2 with lines linewidth 3 title "udp800",\
"tput-tcp200.tr" using 1:2 with lines linewidth 3 title "tcp200",\
"tput-tcp400.tr" using 1:2 with lines linewidth 3 title "tcp400",\
"tput-tcp600.tr" using 1:2 with lines linewidth 3 title "tcp600",\
"tput-tcp800.tr" using 1:2 with lines linewidth 3 title "tcp800"