set output "throughput-udp-no-roll.eps"
set terminal postscript eps enhanced color size 3.5,2.5 font 'Helvetica,18'
set xl "Secons"
set yl "Throughput(bps) "
plot "tput-udp200-no-roll.tr" using 1:2 with lines linewidth 3 lt 1 lc 1 title "udp200-no-role",\
"tput-udp400-no-roll.tr" using 1:2 with lines linewidth 3 lt 1 lc 2 title "udp400-no-role",\
"tput-udp600-no-roll.tr" using 1:2 with lines linewidth 3 lt 1 lc 3 title "udp600-no-role",\
"tput-udp800-no-roll.tr" using 1:2 with lines linewidth 3 lt 1 lc 4 title "udp800-no-role"



