#!/usr/bin/env bash

=() {
    calc="${@//p/+}"
    calc="${calc//x/*}"
    echo "$(($calc))"
}

LINESEXECUTED=`cat log/lasttest.log | wc -l`
LINESEXECUTED=`= 100 x $LINESEXECUTED`
= $LINESEXECUTED / 236
