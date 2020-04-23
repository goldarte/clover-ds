#!/bin/bash

. /scripts/export_env.sh

if ! [ -z $HEADLESS ]
then
    cd /home/user/jMAVSim/out/production
    java -jar jmavsim_run.jar -no-gui
else
    echo Not running...
fi