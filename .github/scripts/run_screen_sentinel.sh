#!/bin/bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native
./target/release/screen-sentinel --debug > screen_sentinel_output.log 2>&1 &
SCREEN_SENTINEL_PID=$!
echo $SCREEN_SENTINEL_PID > screen-sentinel.pid
# Check resource usage every 10 seconds, for 1 minute
for i in {1..6}
do
   sleep 10
   ps -p $SCREEN_SENTINEL_PID -o %cpu,%mem,cmd
done
