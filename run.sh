#!/bin/bash
# SMPPSim Startup Script

cd /home/user/SMPPSim

echo "Checking for old SMPPSim processes..."
OLD_PID=$(pgrep -f "SMPPSim")
if [ ! -z "$OLD_PID" ]; then
    echo "Killing old process: $OLD_PID"
    kill $OLD_PID
    sleep 2
fi

echo "Starting SMPPSim..."
java -jar target/smppsim.jar conf/logback.xml conf/smppsim.props
