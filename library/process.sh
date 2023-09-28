#!/bin/bash

getProcessPidExists() {
    local process="$1"
    local pidFile="$tempDir/$process.pid"
    if [ -f "$pidFile" ]; then
        local pid=$(cat "$pidFile")
        if [ -d "/proc/$pid" ]; then
            set +o errexit
            grep "tool/$process.sh" /proc/$pid/cmdline >/dev/null 2>&1
            local exitCode="$?"
            set -o errexit
            if [ "$exitCode" = "0" ]; then
                echo "true"
                return 0
            fi
        fi
    fi
    echo "false"
}

checkProcessPidExists() {
    local process="$1"
    local exists=$(getProcessPidExists $process)
    if [ "$exists" = "true" ]; then
        echoFatal "process [$process] is running"
    fi
}

checkProcessNameExists() {
    local name="$1"
    set +o errexit
    ps -ef | grep "$name" | grep -v "grep" >/dev/null 2>&1
    local exitCode="$?"
    set -o errexit
    if [ "$exitCode" = "0" ]; then
        echoFatal "process [$name] is running"
    fi
}

checkProcessExists() {
    if [ "$myProcess" != "run" ]; then
        checkProcessPidExists "$myProcess"
        echo "$$" >"$tempDir/$myProcess.pid"
    else
        checkProcessPidExists "build"
        checkProcessPidExists "patch"
        checkProcessPidExists "assemble"
        checkProcessPidExists "check"
        # TODO: check extension specific process
    fi
}
