#!/bin/bash

while IFS= read -rd '' var; do
    export "$var"
done </proc/1/environ

`python /scripts/calculate_gps.py`

echo "MAV_SYS_ID=$MAV_SYS_ID"
echo "PX4_HOME_LAT=$PX4_HOME_LAT"
echo "PX4_HOME_LON=$PX4_HOME_LON"