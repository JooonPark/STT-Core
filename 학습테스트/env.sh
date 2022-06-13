#!/bin/bash

export depth1="  "
export depth2="$depth1  "
export depth3="$depth2  "
export depth4="$depth3  "
export depth5="$depth4  "

#############################################################################################
# section : LOG
#############################################################################################
DEFAULT_LOG_COLOR="-g"
LV1_COLOR="-y"
LV2_COLOR="-c"
LV3_COLOR="-g"
LV4_COLOR="-b"
LV_FATAL_COLOR="-r"
LV_TIME="-m"

export color=$DEFAULT_LOG_COLOR
export depth=$depth1
trace=999

log() {
    cecho $DEFAULT_LOG_COLOR "> $*"
}

log_time() {
    cecho $LV_TIME "$*"
}

log_format() {
    cecho $color "$depth> $*"
}

cecho_lv1() {
    [ "$trace" -ge "1" ] && { color=$LV1_COLOR; depth=""; log_format "$*"; }
}

cecho_lv2() {
    [ "$trace" -ge "2" ] && { color=$LV2_COLOR; depth=$depth1; log_format "$*"; }
}

cecho_lv3() {
    [ "$trace" -ge "3" ] && { color=$LV3_COLOR; depth=$depth2; log_format "$*"; }
}

cecho_lv4() {
    [ "$trace" -ge "4" ] && { color=$LV4_COLOR; depth=$depth3; log_format "$*"; }
}

ccat_format() {
    files="$*"; IFS=''
    if [ -z "$files" ]; then
        while read line; do
            log_format "$line"
        done <"${1:-/dev/stdin}"
    else
        for file in $files; do
            while read line; do
                log_format "$line"
            done < $file
        done
    fi
}

ccat_lv1() {
    [ "$trace" -ge "1" ] && { color=$LV1_COLOR; depth=""; ccat_format "$*"; }
}

ccat_lv2() {
    [ "$trace" -ge "2" ] && { color=$LV2_COLOR; depth=$depth1; ccat_format "$*"; }
}

ccat_lv3() {
    [ "$trace" -ge "3" ] && { color=$LV3_COLOR; depth=$depth2; ccat_format "$*"; }
}

ccat_lv4() {
    [ "$trace" -ge "4" ] && { color=$LV4_COLOR; depth=$depth3; ccat_format "$*"; }
}

cecho_fatal() {
    color=$LV_FATAL_COLOR; depth=""
    echo "$*"
#    log_format "$*"
    echo "[[ ABORT : $(date -R) ]]"
#    log_format "[[ ABORT : $(date -R) ]]"
    exit 1
}

check_files() {
    files="$@"; [ -z "$files" ] && log_fatal "$FUNCNAME : argument missing"
    for file in ${files[@]}; do
        [ ! -f "$file" ] && log_fatal "$FUNCNAME : can't find $file"
    done
}

check_directories() {
    dirs=$@
    for dir in $dirs; do
        [ ! -d "$dir" ] && mkdir -p $dir
    done
}

print_date() {
    comment=$1
    [ -z "$comment" ] && comment=begin
    log_time "[[ $comment : `date -R` ]]"
}

export trace LV1_COLOR LV2_COLOR LV3_COLOR LV4_COLOR LV_FATAL_COLOR LV_TIME
export -f cecho_fatal cecho_lv1 cecho_lv2 cecho_lv3 cecho_lv4 log log_time log_format
export -f ccat_lv1 ccat_lv2 ccat_lv3 ccat_lv4 ccat_format
