#!/bin/bash

# imports
source ./lib.sh

szScript="#!/bin/bash

while [ true ]; do
    cd \"\$(dirname \"\$0\")\"
    java -Xms1024M -Xmx1024M -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar paper.jar nogui
    
    printf \"[start.sh] Restarting server...\\n\"
    printf \"[start.sh] Press CTRL + C to stop\\n\"
    
    sleep 3
done"
    

function CreateStartScript {
    cprintf "Creating startup script..."
    
    printf "%s\n" "$szScript" > "$1"
    chmod +x $1
    
    if [[ $? -eq 0 ]]; then
        cprintf "Wrote start.sh -> $1"
    else
        cprintf "Error: Failed to write start.sh to $1"
        exit 1
    fi
}

