rm loss-rate.tr
awk 'END {loss_rate=$11/$9; print loss_rate >> "loss-rate.tr"; }' queue-mon
