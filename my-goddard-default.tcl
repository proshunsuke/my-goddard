#Set random seed
global defaultRNG
$defaultRNG seed 15

# パラメータ設定


# 実験用パラメータ
set digestUserRate 0.2
set gateBandWidthRate 0.3
set gateCommentRate 0.1
set semiGateBandWidthRate 0.3
set semiGateCommentRate 0.2
set notGetDigestRate 0.2
set connectNomalNodeRate 0.25

# 帯域幅割合
array set bandwidthRatio {
    3.000 30
    1.500 3
    1.024 56
    0.768 13
    0.640 3
    0.512 4
    0.448 25
    0.384 17
    0.320 29
    0.256 20
}

# コメント数割合
array set commentRatio {
    25 2
    22 2
    20 3
    17 5
    15 22
    12 28
    10 33
    7 36
    5 36
    2 33
}
