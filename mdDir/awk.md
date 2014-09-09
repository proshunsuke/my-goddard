# awk
## awkとは

AWK はフィルタリングによく使用されるコマンドであるが、同様にしてフィルタリングに使用される grep や cut と決定的に違うところは、 AWK 自体が独立した一つのスクリプト言語であるということだ。つまり、AWK は正確にはコマンドではなく、AWK スクリプト・インタプリタである。

## awkの構文
パターンとアクション
---------------------------------------
 AWK はテキストファイルもしくは標準入力からテキストを１行ずつ読み込み、各パターンとのマッチングを行う。

 例えば
 `awk '{ print $1 }'`

 は、シングルくクォーテーションで囲まれた部分がパターンとアクション。ここではパターンは省略されているので、すべての行とマッチングが成功する。

## test-goddard.tclの場合

次のawk構文の意味

```
set awkCode {
        {
            if ($8 == 3000) {
                if ($2 >= t_end_tcp) {
                    tput_tcp = bytes_tcp * 8 / ($2 - t_start_tcp);
                    print $2, tput_tcp >> "tput-tcp.tr";
                    t_start_tcp = $2;
                    t_end_tcp   = $2 + 2;
                    bytes_tcp = 0;
                }
                if ($1 == "r") {
                    bytes_tcp += $6;
                }
            }
            else if ($8 == 3001) {
                if ($2 >= t_end_udp) {
                    tput_udp = bytes_udp * 8 / ($2 - t_start_udp);
                    print $2, tput_udp >> "tput-udp.tr";
                    t_start_udp = $2;
                    t_end_udp   = $2 + 2;
                    bytes_udp = 0;
                }
                if ($1 == "r") {
                    bytes_udp += $6;
                }
            }
        }
    }

```

この標準入力に対して、`awk $awkCode out.tr`を実行する。

`out.tr`の中身の一部は以下である。

`r 72.601139 10 7 udp 1000 ------- 3024 10.5 7.8 14816 519391`

awkCodeの中身について

`$8`とか`$1`は、`out.tr`の行番号である。`$8`が3000か3001以外は評価しないようである。おそらく3000はtcp、3001はudpということだろう。

さらに`$2 >= t_end_udp`であった場合に限り、`tput-udp.tr`というトレースファイルに書き込みしている。

おそらく`$2`が時刻で、`t_start_udp`はスタートした時間、`t_end_udp`は終わった時間を表している。

`tput-udp.tr`をグラフ化しており、縦が"Throughput (bps)"ということなので、おそらく`$2`は時刻、`tput_udp`が"Throughput"を表しているのだろう。

`tput-udp`は次の式で表されている。

`tput_udp = bytes_udp * 8 / ($2 - t_start_udp);`


