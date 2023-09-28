#!/bin/bash

if [ -z "$SCL_ECHO_PREFIX" ]; then
    export SCL_ECHO_PREFIX="-"
fi

echoColor() {
    local color="$1"
    local text="$2"
    local message=""
    if [ "$SCL_ECHO_COLOR" != "false" ]; then
        message="$color"
    fi
    message="$message[$(logTimestamp)]"
    if [ -n "$SCL_ECHO_PREFIX" ]; then
        message="$message $SCL_ECHO_PREFIX"
    fi
    message="$message $text"
    if [ "$SCL_ECHO_COLOR" != "false" ]; then
        message="$message\e[m"
    fi
    echo -e "$message"
    if [ -n "$SCL_LOG_FILE" ]; then
        local dir=$(dirname "$SCL_LOG_FILE")
        createDirNoLog "$dir"
        echo -e "$message" >>"$SCL_LOG_FILE"
    fi
}

echoGray() {
    echoColor "\e[90m" "$1"
}

echoRed() {
    echoColor "\e[91m" "$1"
}

echoGreen() {
    echoColor "\e[92m" "$1"
}

echoYellow() {
    echoColor "\e[93m" "$1"
}

echoBlue() {
    echoColor "\e[94m" "$1"
}

echoPurple() {
    echoColor "\e[95m" "$1"
}

echoInfo() {
    echoColor "\e[m" "$1"
}

echoError() {
    echoRed "$1"
}

echoFatal() {
    echoError "$1"
    exit 1
}

echoWarning() {
    echoYellow "$1"
}

echoSkip() {
    local run="$1"
    local value="$2"
    echoWarning "skip $run because ${value} is ${!value}"
}

echoCompleted() {
    if [ -z "$parentFile" ]; then
        local startTime="$SCL_PROCESS_START_TIME"
        if [ -z "$startTime" ]; then
            startTime="$SCL_ENTRYPOINT_TIME"
        fi
        local endTime=$(currentSeconds)
        local elapsedTime=$(getElapsedTime "$startTime" "$endTime")
        echoGreen "$myFile : completed [$elapsedTime]"
    else
        echoPurple "$myFile > $parentFile"
    fi
}

echoValues() {
    if [ "$SCL_CFG_DISABLE_ECHO_VALUES" = "true" ]; then
        return 0
    fi

    local value
    local maxLength="1"
    for value in "$@"; do
        local typesetResult
        set +o errexit
        typesetResult=$(typeset -p $value 2>/dev/null)
        set -o errexit
        local message="\e[94m[$(logTimestamp)] "
        if [ -n "$SCL_ECHO_PREFIX" ]; then
            message="$message$SCL_ECHO_PREFIX "
        fi
        message="$message%-${maxLength}s = %s\n\e[m"

        if [ -n "$SCL_LOG_FILE" ]; then
            local dir=$(dirname "$SCL_LOG_FILE")
            createDirNoLog "$dir"
        fi

        if [[ "$typesetResult" =~ "declare -a" ]]; then
            local arrayValue="${value}[*]"
            printf "$message" "$value" "${!arrayValue}"

            if [ -n "$SCL_LOG_FILE" ]; then
                printf "$message" "$value" "${!arrayValue}" >>"$SCL_LOG_FILE"
            fi
        else
            printf "$message" "$value" "${!value}"

            if [ -n "$SCL_LOG_FILE" ]; then
                printf "$message" "$value" "${!value}" >>"$SCL_LOG_FILE"
            fi
        fi
    done
}

checkEmptyValues() {
    local value
    for value in "$@"; do
        local typesetResult
        set +o errexit
        typesetResult=$(typeset -p $value 2>/dev/null)
        set -o errexit
        if [[ "$typesetResult" =~ "declare -a" ]]; then
            local arrayValue="${value}[@]"
            arrayValue=(${!arrayValue})
            if [ "${#arrayValue[@]}" = "0" ]; then
                echoError "$value is empty"
                return 1
            fi
        else
            if [ -z "${!value}" ]; then
                echoError "$value is empty"
                return 1
            fi
        fi
    done
}

echoAndCheckEmptyValues() {
    echoValues "$@"
    checkEmptyValues "$@"
}
