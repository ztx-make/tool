#!/bin/bash

myPath=$(readlink -f $0)
myFile=$(basename $myPath)
toolDir=$(dirname $myPath)
source "$toolDir/library/library.sh"

resetPatch() {
    clearDir "$patchDir"

    execCmd "cd $sourceDir"
    if [ "$versionControl" = "git" ]; then
        execCmd "git reset --hard"
        execCmd "git clean -df"
    elif [ "$versionControl" = "repo" ]; then
        execCmd "repo forall -j$cpuNum -q -c 'git reset --hard; git clean -fd'"
    fi

    safeExec baseResetPatch
    safeExec seriesResetPatch
    safeExec targetResetPatch
}

makePatch() {
    safeExec baseMakePatch
    safeExec seriesMakePatch
    safeExec targetMakePatch
}

applyPatch() {
    if [ ! -d "$patchDir" ]; then
        echoWarning "patch dir [$patchDir] not exists"
    elif [ -z "$(ls -A $patchDir)" ]; then
        echoWarning "patch dir [$patchDir] empty"
    else
        execCmd "cp -rf $patchDir/* $sourceDir"
    fi

    safeExec baseApplyPatch
    safeExec seriesApplyPatch
    safeExec targetApplyPatch
}

execTask "reset patch"
execTask "make patch"
execTask "apply patch"
echoCompleted
