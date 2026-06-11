#!/usr/bin/env bash

if [ $# -eq 0 ]; then
    echo "No Arg where given!"
    exit 1
fi

while getopts "tgc" opt; do
    case $opt in
        t)
            colordots theme set transparent
            ;;
        g)
            colordots theme set gruv
            ;;
        c)
            colordots theme set catppuccin
            ;;
        *)
            echo "Unkown Arg!"
            ;;
    esac

done

