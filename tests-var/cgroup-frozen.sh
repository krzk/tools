#!/bin/bash

cd /sys/fs/cgroup/freezer
mkdir frozen
cd frozen
echo "FROZEN" > freezer.state
cat freezer.state

echo PID > cgroup.procs

echo mem > /sys/power/state
