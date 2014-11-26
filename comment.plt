set output "comment.eps"
set terminal postscript eps enhanced color size 3.5,2.5 font 'Helvetica,18'
set xl "Comment number"
set yl "ratio(%) "
plot "comment-analysis.tr" using 1:2 with lines linewidth 3 lt 1 lc 1 title "comment"