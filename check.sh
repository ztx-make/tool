#!/bin/bash

myPath=$(readlink -f $0)
myFile=$(basename $myPath)
toolDir=$(dirname $myPath)
source "$toolDir/library/library.sh"

checkOutput() {
    loadRecord "last" "build"
    # TODO
    if [ -z $(getRecord TASK_BUILD_SYSTEM_SUCCESS_TIME) ]; then
        echoFatal "build system not success"
    fi
    unloadRecord

    safeExec baseCheckOutput
    safeExec seriesCheckOutput
    safeExec targetCheckOutput
}

if [ -n "$module" ]; then
    echoFatal "check not support module"
fi

execTask "check output"
echoCompleted
