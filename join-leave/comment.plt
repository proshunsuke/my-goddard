set output "comment.eps"
set terminal postscript eps enhanced color size 3.5,2.5 font 'Helvetica,18'
set xl "Number of comments"
set yl "Rate of nodes[%]"
plot "comment-analysis.tr" using 1:2 with lines linewidth 3 title "comment"