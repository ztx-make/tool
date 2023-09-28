#!/bin/bash

if [ -z "$TIME_SERVER_URL" ]; then
    TIME_SERVER_URL="https://baidu.com"
fi

loadTimeOffset() {
    if [ -z "$ZTX_MAKE_TIME_OFFSET" ]; then
        local serverTimeStr=$(curl -k -I "$TIME_SERVER_URL" 2>/dev/null | grep -i "^date:" | sed "s/^[Dd]ate: //g")
        if [ -n "$serverTimeStr" ]; then
            local serverTime=$(date +%s -d "$serverTimeStr")
            local localTime=$(date +%s)
            local offset=$((serverTime - localTime))
            export ZTX_MAKE_TIME_OFFSET="$offset"
        else
            echoFatal "load time offset error"
        fi
    fi
}

currentSeconds() {
    local offset="$ZTX_MAKE_TIME_OFFSET"
    if [ -z "$offset" ]; then
        offset="0"
    fi
    date +%s -d "$ZTX_MAKE_TIME_OFFSET second"
}

currentLocalSeconds() {
    date +%s
}

currentHMS() {
    date +%H:%M:%S -d @$(currentSeconds)
}

currentYmdHMS() {
    date "+%Y%m%d%H%M%S" -d @$(currentSeconds)
}

logTimestamp() {
    date "+%Y/%m/%d %H:%M:%S" -d @$(currentSeconds)
}

getElapsedTimeSeconds() {
    local start="$1"
    local end="$2"
    local elapsed=$(($end - $start))
    echo "$elapsed"
}

getElapsedTimeText() {
    local elapsed="$(getElapsedTimeSeconds "$1" "$2")"
    if [ "$elapsed" -lt "60" ]; then
        echo "${elapsed}s"
    elif [ "$elapsed" -lt "3600" ]; then
        echo "$(($elapsed / 60))m $(($elapsed % 60))s"
    else
        echo "$(($elapsed / 3600))h $(($elapsed % 3600 / 60))m $(($elapsed % 60))s"
    fi
}
