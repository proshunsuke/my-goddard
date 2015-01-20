BEGIN {
    recvdSize = 0
    startTime = 400
    stopTime = 0
    udp_num = 0
    tcp_num = 0
    udp_throughput = 0
    tcp_throughput = 0
}

  {
      event = $1
      time = $2
      node_id = $3
      pkt_size = $6

      # Update total received packets' size and store packets arrival time
      if ($8 == 3000) {
          if (time >= t_end_tcp) {
              tput_tcp = bytes_tcp * 8 / (time - t_start_tcp)/1000
              tcp_throughput += tput_tcp
              t_start_tcp = time
              t_end_tcp = time + 2
              bytes_tcp = 0
              tcp_num += 1
          }
          if (event == "r") {
              bytes_tcp += pkt_size
          }
      }
      else if ($5 == "cbr") {
          if (time >= t_end_udp) {
              tput_udp = bytes_udp * 8 / (time - t_start_udp)/1000
              print $2, tput_udp >> "join-leave-tput-udp.tr"
              udp_throughput += tput_udp
              t_start_udp = time
              t_end_udp = time + 2
              bytes_udp = 0
              udp_num += 1
          }
          if (event == "r") {
              bytes_udp += pkt_size
          }
      }
  }

  END {
      res = udp_throughput/udp_num
      if (ARGV[1] == "out200.tr") {
          user_n = 200
      } else if (ARGV[1] == "out400.tr") {
          user_n = 400
      } else if (ARGV[1] == "out600.tr") {
          user_n = 600
      }  else if (ARGV[1] == "out800.tr") {
          user_n = 800
      }
      system("echo " user_n " " res " >> average.tr");

      printf("Average Udp_Throughput[kbps] = %.2f\n",(res))
      # printf("Average Tcp_Throughput[kbps] = %.2f\n",(tcp_throughput/tcp_num))
  }

