BEGIN {
    ROOT = 200
    num = 0
    totalDelay = 0
}
{
    event = $1
    time = $2
    startNode = $3
    finNode = $4

    if (event == "+" && startNode == ROOT && num < 100) {
        startTime[finNode] = time
    }

    if (event == "r" && startNode == ROOT && num < 100) {
        if (startTime[finNode] >= 0) {
            endTime[finNode] = time
            delay[num] = endTime[finNode] - startTime[finNode]
            totalDelay += delay[num]

            printf("node:%d,  num: %d, startTime: %.2f, endTime: %.2f, delay: %.2f\n",finNode,num,startTime[finNode],endTime[finNode],delay[num])

            startTime[finNode] = -1
            num++
        }
    }
}
END {
    res = totalDelay / num
    printf("Average Delay[sec] = %.2f\n",res)
}