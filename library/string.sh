#!/bin/bash

toBigCamel() {
    local strs=($1)
    local result
    local i
    for ((i = 0; i < ${#strs[@]}; i++)); do
        result="$result$(echo ${strs[i]:0:1} | awk '{print toupper($0)}')$(echo ${strs[i]:1} | awk '{print tolower($0)}')"
    done
    echo "$result"
}

toLittleCamel() {
    local strs=($1)
    local result
    local i
    for ((i = 0; i < ${#strs[@]}; i++)); do
        if [ "$i" = "0" ]; then
            result="$(echo ${strs[i]} | awk '{print tolower($0)}')"
        else
            result="$result$(echo ${strs[i]:0:1} | awk '{print toupper($0)}')$(echo ${strs[i]:1} | awk '{print tolower($0)}')"
        fi
    done
    echo "$result"
}

toBigUnderline() {
    local strs=($1)
    local result
    local i
    for ((i = 0; i < ${#strs[@]}; i++)); do
        if [ "$i" = "0" ]; then
            result="$(echo ${strs[i]} | awk '{print toupper($0)}')"
        else
            result="${result}_$(echo ${strs[i]} | awk '{print toupper($0)}')"
        fi
    done
    echo "$result"
}

toLittleUnderline() {
    local strs=($1)
    local result
    local i
    for ((i = 0; i < ${#strs[@]}; i++)); do
        if [ "$i" = "0" ]; then
            result="$(echo ${strs[i]} | awk '{print tolower($0)}')"
        else
            result="${result}_$(echo ${strs[i]} | awk '{print tolower($0)}')"
        fi
    done
    echo "$result"
}
