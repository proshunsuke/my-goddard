#!/bin/sh
# 環境変数 TCLPKG が定義されていれば auto_path に追加
if {[info exist env(TCLPKG)]} {
    lappend auto_path $env(TCLPKG)
}
package require Draw

# ----------------------------------------------------------------------------
# メイン
# ----------------------------------------------------------------------------
wm title . "canvas"

set color_bg   "#f0fff8"
set color_grid "#c0e0d0"
set color_draw "#804040"

# キャンバスの生成
set cw 200
set ch 200
canvas .can \
        -width              $cw \
        -height             $ch \
        -borderwidth        0 \
        -highlightthickness 0 \
        -background         $color_bg
pack .can

# 方眼
for {set y 0} {$y < $ch} {incr y 10} {
    .can create line 0 $y $cw $y -fill $color_grid
}
for {set x 0} {$x < $cw} {incr x 10} {
    .can create line $x 0 $x $ch -fill $color_grid
}

# クラス Draw のインスタンス pen を生成
set pen [Draw new]

# メソッド init で描画色を設定
$pen init $color_draw

# マウス左ボタンを .can 上で押した時、メソッド first で座標を取得
bind .can <Button-1> {$pen first %x %y}

# マウス左ボタンを押しながら .can 上を移動した時、メソッド line を実行
bind .can <B1-Motion> {$pen line %W %x %y}