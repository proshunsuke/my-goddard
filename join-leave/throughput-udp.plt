set output "throughput-udp.eps"
set terminal postscript eps enhanced color size 3.5,2.5 font 'Helvetica,18'
set xl "Time[sec]"
set yl "Throughput[kbps]"
plot "tput-udp200.tr" using 1:2 with lines linewidth 3 title "udp200",\
"tput-udp400.tr" using 1:2 with lines linewidth 3 title "udp400",\
"tput-udp600.tr" using 1:2 with lines linewidth 3 title "udp600",\
"tput-udp800.tr" using 1:2 with lines linewidth 3 title "udp800"



