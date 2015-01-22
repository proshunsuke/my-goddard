BEGIN {
    bw = 0
    num = 0
}

  {
      bw += $2
      num++
  }

  END {
      res = (bw/num)
      printf("Average Udp_Throughput[kbps] = %.2f\n",(res))
  }
