#!/bin/bash

# Installs Minecraft server from a preset

# imports
source ./lib.sh
source ./patches/startscript.sh
source ./patches/vanillasmpplus.sh

## app
szHelpMsg=$(cat << EOF
Usage: $0 [options]

Options:
  -h, --help        Display this help message
  -m, --mcver       Specify Minecraft version to install to server
                    (latest or x.xx.x format)
  -s, --software    Specify server software to use with Minecraft server
                    (vanilla, paper, purpur)
  -p, --preset      Select presets to install with extra features
                    (vanillasmpplus)
  -o, --output      Where to download the server .jar file
\n\0
EOF
)

# flag arg vars (filled by user)
szFlagMcVer=""
szFlagSoftware=""
szFlagPreset=""
szFlagOutput="./server" # Default to ./server in case output path is not provided

function GenerateConfigs {
    local server_dir="$1"

    # Check if directory exists
    if [ ! -d "$server_dir" ]; then
        cprintf "Error: Directory $server_dir does not exist"
        return 1
    fi

    # Check if start.sh exists
    if [ ! -f "$server_dir/start.sh" ]; then
        cprintf "Error: start.sh not found in $server_dir"
        return 1
    fi

    # Check if tmux is installed
    if ! command -v tmux &> /dev/null; then
        cprintf "Error: tmux is not installed"
        return 1
    fi

    # Create tmux session name based on directory
    # session_name="mc_$(basename "$server_dir" | tr -d '[:space:]')"
    session_name="tmux-mc-$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 8)"

    # Check if tmux session already exists
    if tmux has-session -t "$session_name" 2>/dev/null; then
        cprintf "Error: tmux session $session_name already exists"
        return 1
    fi

    # Create new tmux session
    tmux new-session -d -s "$session_name" || {
        cprintf "Error: Failed to create tmux session"
        return 1
    }

    # Run start.sh in the tmux session
    tmux send-keys -t "$session_name" "cd $server_dir && chmod +x start.sh && ./start.sh" C-m

    cprintf "Started Minecraft server instance: $session_name"
    # echo "Monitoring server startup..."

    # Monitor server logs for world generation completion
    local log_file="$server_dir/logs/latest.log"
    local timeout=600  # 10 minutes timeout
    local start_time=$(date +%s)

    while [ $(( $(date +%s) - start_time )) -lt $timeout ]; do
        if [ -f "$log_file" ]; then
            # Check for common "Done" message indicating server is ready
            if grep -q "Done.*! For help, type \"help\"" "$log_file" || \
               grep -q "Preparing spawn area" "$log_file" || \
               grep -q "All dimensions are saved" "$log_file"; then
                #echo "Server has finished world generation" # debug info
                
                # Send stop command to server
                tmux send-keys -t "$session_name" "stop" C-m
                
                cprintf "Waiting for server instance..."
                
                # Wait for server to shutdown
                sleep 10
                
                # Kill tmux session
                tmux kill-session -t "$session_name" 2>/dev/null
                # echo "Server stopped and tmux session terminated" # debug info
                return 0
            fi
        fi
        sleep 5
    done

    cprintf "Error: Timeout waiting for server startup"
    tmux kill-session -t "$session_name" 2>/dev/null
    return 1
}

function PromptRootUser {
    if [ "$EUID" -eq 0 ]; then
        _cprintfraw "Warning: Running this script as root user is not recommended, proceed? [Y/n]"
        read -p " " proceed
        proceed=${proceed:-N}
        case $proceed in
            [Yy]* )
                ;;
            *)
                exit 0
                ;;
        esac
    fi
}

function PromptBeforeInstall {
    _cprintfraw "Proceed with installation? [Y/n]"
    read -p " " proceed
    proceed=${proceed:-Y}
    case $proceed in
        [Nn]* )
            exit 0
            ;;
        *)
            ;;
    esac
}

function main {
    PromptRootUser

    packages=("curl" "wget" "tmux")
    _CheckDependencies "${packages[@]}"
    
    if ! command -v java &>/dev/null; then
        cprintf "Error: java binary was not found, please install Java 21+ to proceed."
        exit 1
    else
        # Check java version
        local szJavaVersion
        szJavaVersion=$(java --version | head -n 1 | grep -oP '\d+' | head -n 1)
        
        if [[ -z "$szJavaVersion" ]]; then
            cprintf "Error: Could not determine Java version, exiting..."
            exit 1
        fi
        
        cprintf "Detected Java version $szJavaVersion"
    fi
    
    # Validate inputs
    if [[ -z $szFlagMcVer ]]; then
        cprintf "Error: --mcver is required"
        printf "$szHelpMsg"
        exit 1
    fi

    if [[ -z $szFlagSoftware ]]; then
        cprintf "Error: --software is required"
        printf "$szHelpMsg"
        exit 1
    fi

    if [[ "$szFlagSoftware" != "paper" && "$szFlagSoftware" != "vanilla" && "$szFlagSoftware" != "purpur" ]]; then
        cprintf "Error: Invalid software '$szFlagSoftware'. Supported: vanilla, paper, purpur"
        exit 1
    fi

    if [[ "$szFlagMcVer" == "latest" ]]; then
        cprintf "Fetching latest Minecraft version for $szFlagSoftware..."
        # TODO: Implement logic to fetch latest version from PaperMC API or other sources
        cprintf "Error: 'latest' version not yet supported"
        exit 1
    fi

    cprintf "Installing Minecraft server $szFlagSoftware $szFlagMcVer..."

    if [[ "$szFlagSoftware" == "paper" ]]; then
        # Check if version exists in PaperMC API
        VERSION_CHECK=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/$szFlagMcVer")
        if [[ $(echo "$VERSION_CHECK" | grep -o '"error"') ]]; then
            cprintf "Error: Minecraft version $szFlagMcVer is not available for PaperMC"
            exit 1
        fi

        # Get the latest build
        LATEST_BUILD=$(echo "$VERSION_CHECK" | grep -o '[0-9]\+' | tail -1)
        if [[ -z $LATEST_BUILD ]]; then
            cprintf "Error: No builds found for version $szFlagMcVer"
            exit 1
        fi
        
        PromptBeforeInstall

        # Construct the download URL
        szJarUrl="https://api.papermc.io/v2/projects/paper/versions/$szFlagMcVer/builds/$LATEST_BUILD/downloads/paper-$szFlagMcVer-$LATEST_BUILD.jar"
        #cprintf "PaperMC JAR URL for version $szFlagMcVer (build $LATEST_BUILD):"
        #cprintf "$szJarUrl"

        cprintf "Downloading PaperMC build $LATEST_BUILD..."
        
        mkdir -p ${szFlagOutput}
        wget -t 3 "$szJarUrl" -O "${szFlagOutput}/paper.jar" || {
            cprintf "Error: Failed to download JAR"
            exit 1
        }
        
        cprintf "Download complete for PaperMC -> paper.jar"
        
        # Create start.sh
        szStartPath="${szFlagOutput}/start.sh"
        
        CreateStartScript "${szStartPath}"
        
        # Create and automatically agree to eula.txt
        echo "eula=true" > ${szFlagOutput}/eula.txt
        cprintf "Wrote eula.txt with eula=true"
        
        # Check preset and apply patches
        if [[ "$szFlagPreset" == "vanillasmpplus" ]]; then
            # start the server to generate configs, stop it and then apply patches
            GenerateConfigs $szFlagOutput
            Patch_VSP_All $szFlagOutput
            
            # remove the generated world and make sure you dont delete anti-xray/per-world configs
            # find world/ ! -name 'paper-world.yml' -delete     # We didn't modify anything here
            rm -r ${szFlagOutput}/world/
            find ${szFlagOutput}/world_nether/ -type f ! -name 'paper-world.yml' -delete
            find ${szFlagOutput}/world_the_end/ -type f ! -name 'paper-world.yml' -delete
            find ${szFlagOutput}/world_nether/ -type d -empty -delete
            find ${szFlagOutput}/world_the_end/ -type d -empty -delete
            
            cprintf "Plugins installing is not implemented yet with this installer"
            cprintf "With this preset, install the following plugins:"
            cprintf "Simple Voice Chat, FreedomChat, SkinsRestorer, Lightning Grim Anticheat\n"
            cprintf "https://modrinth.com/plugins"
        fi
    else
        cprintf "Error: Only 'paper' software is currently implemented"
        exit 1
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            printf "$szHelpMsg"
            exit 0
            ;;
        -m|--mcver)
            if [[ -z $2 ]]; then
                cprintf "Error: --mcver requires a value"
                exit 1
            fi
            szFlagMcVer="$2"
            shift 2
            ;;
        -s|--software)
            if [[ -z $2 ]]; then
                cprintf "Error: --software requires a value"
                exit 1
            fi
            szFlagSoftware="$2"
            shift 2
            ;;
        -p|--preset)
            if [[ -n $2 ]]; then
                szFlagPreset="$2"
            fi
            shift 2
            ;;
        -o|--output)
            if [[ -n $2 ]]; then
                szFlagOutput="$2"
            fi
            shift 2
            ;;
        *)
            printf "Unknown option: $1"
            exit 1
            ;;
    esac
done

main

