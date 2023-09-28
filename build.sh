#!/bin/bash

myPath=$(readlink -f $0)
myFile=$(basename $myPath)
toolDir=$(dirname $myPath)
source "$toolDir/library/library.sh"

# TODO: system / module replace to generic name

buildModule() {
    execCmd "cd $buildWorkingDir"

    safeExec baseBuildModule
    safeExec seriesBuildModule
    safeExec targetBuildModule
}

buildSystem() {
    execCmd "cd $buildWorkingDir"

    safeExec baseBuildSystem
    safeExec seriesBuildSystem
    safeExec targetBuildSystem
}

execFile "patch" "--build"

if [ -n "$module" ]; then
    execTask "build module"
else
    execTask "build system"
fi

execFile "assemble"

echoCompleted
