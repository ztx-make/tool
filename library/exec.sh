#!/bin/bash

safeSource() {
    local script="$1"
    if [ -f "$script" ]; then
        source "$script"
        ZTX_MAKE_SAFE_SOURCE_RESULT="success"
        return 0
    fi
    ZTX_MAKE_SAFE_SOURCE_RESULT="not_exists"
    return 0
}

safeExec() {
    local cmd="$1"
    local cmdFound="true"
    command -v "$cmd" >/dev/null 2>&1 || cmdFound="false"
    if [ "$cmdFound" = "true" ]; then
        ZTX_MAKE_SAFE_EXEC_RESULT="success"
        execCmd "$cmd"
    else
        ZTX_MAKE_SAFE_EXEC_RESULT="not_exists"
    fi
}

execCmd() {
    local cmd="$1"

    if [ -z "$ZTX_MAKE_EXEC_CMD_OUTPUT_FILE" ]; then
        echoGray "$cmd"
    else
        echoGray "$cmd >> $ZTX_MAKE_EXEC_CMD_OUTPUT_FILE 2>&1"
    fi

    if [ "$ZTX_MAKE_DISABLE_EXEC_CMD" != "true" ]; then
        if [ -z "$ZTX_MAKE_EXEC_CMD_OUTPUT_FILE" ]; then
            eval "$cmd"
        else
            local dir=$(dirname "$ZTX_MAKE_EXEC_CMD_OUTPUT_FILE")
            createDirNoLog "$dir"
            eval "$cmd >> $ZTX_MAKE_EXEC_CMD_OUTPUT_FILE 2>&1"
        fi
        return "$?"
    fi
}

execTask() {
    local title="$1"
    local params=("${@:2}")

    local function="$(toLittleCamel "$title")"
    local disable="ZTX_MAKE_DISABLE_$(toBigUnderline "$title")"

    echoPurple "$myFile : $title"
    export ZTX_MAKE_ECHO_PREFIX="$ZTX_MAKE_ECHO_PREFIX-"

    if [ "${!disable}" != "true" ]; then
        $function "${params[@]}"
    else
        echoSkip "$function" "$disable"
    fi

    appendTimeRecord "TASK_$(toBigUnderline "$title")_SUCCESS_TIME"

    if [ "${#ZTX_MAKE_ECHO_PREFIX}" -gt "0" ]; then
        export ZTX_MAKE_ECHO_PREFIX="${ZTX_MAKE_ECHO_PREFIX:1}"
    fi
}

execFile() {
    local fileName="$1.sh"
    local params=("${@:2}")

    echoPurple "$myFile > $fileName"
    export ZTX_MAKE_ECHO_PREFIX="$ZTX_MAKE_ECHO_PREFIX-"

    bash "$toolDir/$fileName" "${params[@]}"

    if [ "${#ZTX_MAKE_ECHO_PREFIX}" -gt "0" ]; then
        export ZTX_MAKE_ECHO_PREFIX="${ZTX_MAKE_ECHO_PREFIX:1}"
    fi
}

run() {
    bash "$toolDir/run.sh" "$@"
}
