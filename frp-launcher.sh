#!/bin/bash

# Script Idea: @tismatis
# The format of the port mapping file is protocol,targetIp,targetPort,remotePort

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
FRPC_CONFIG_FILE="$SCRIPT_DIR/frpc_multi_proxies.toml"
FRPC_PATH="$SCRIPT_DIR/frpc"
PORT_MAPPINGS_FILE=""
SERVER_IP=""
SERVER_PORT=""
CONFIG_FILE=""
ACTION=""

show_banner() {
    cat << "EOF"
 ______ _____  _____    _              _    _ _   _  _____ _    _ ______ _____  
|  ____|  __ \|  __ \  | |        /\  | |  | | \ | |/ ____| |  | |  ____|  __ \ 
| |__  | |__) | |__) | | |       /  \ | |  | |  \| | |    | |__| | |__  | |__) |
|  __| |  _  /|  ___/  | |      / /\ \| |  | | . ` | |    |  __  |  __| |  _  / 
| |    | | \ \| |      | |____ / ____ \ |__| | |\  | |____| |  | | |____| | \ \ 
|_|    |_|  \_\_|      |______/_/    \_\____/|_| \_|\_____|_|  |_|______|_|  \_\
                                                                                 
EOF
}

start_frpc() {
    if [ -z "$PORT_MAPPINGS_FILE" ]; then
        echo "Usage: $0 --start <portMappingsFile> [--serverIP <serverIP>] [--serverPort <serverPort>] [--config <configFile>]"
        exit 1
    fi

    if [ ! -f "$PORT_MAPPINGS_FILE" ]; then
        echo "File $PORT_MAPPINGS_FILE not found!"
        exit 1
    fi

    if [ -n "$CONFIG_FILE" ]; then
        if [ -f "$CONFIG_FILE" ]; then
            echo "Using server configuration from $CONFIG_FILE"
            SERVER_IP=$(grep -oP '(?<=serverAddr\s=\s)\S+' "$CONFIG_FILE")
            SERVER_PORT=$(grep -oP '(?<=serverPort\s=\s)\S+' "$CONFIG_FILE")
        else
            echo "Config file $CONFIG_FILE not found!"
            exit 1
        fi
    fi

    if [ -z "$SERVER_IP" ] || [ -z "$SERVER_PORT" ]; then
        echo "Server IP or Port not provided and not found in config file!"
        exit 1
    fi

    show_banner

    cat <<EOF > $FRPC_CONFIG_FILE
serverAddr = "$SERVER_IP"
serverPort = $SERVER_PORT

EOF

    while IFS=, read -r TYPE_PORT LOCAL_IP LOCAL_PORT REMOTE_PORT; do
        [[ "$TYPE_PORT" =~ ^#.* ]] && continue
        
        echo "Adding ${TYPE_PORT} from ${LOCAL_IP}:${LOCAL_PORT} to :${REMOTE_PORT} to configuration"
        
        cat <<EOF >> $FRPC_CONFIG_FILE
[[proxies]]
name = "${LOCAL_IP}_${LOCAL_PORT}_${REMOTE_PORT}"
type = "${TYPE_PORT}"
localIp = "${LOCAL_IP}"
localPort = ${LOCAL_PORT}
remotePort = ${REMOTE_PORT}

EOF

        sleep 1
    done < "$PORT_MAPPINGS_FILE"

    echo "All proxies added to the configuration file."

    $FRPC_PATH -c $FRPC_CONFIG_FILE &

    echo "frpc started with the new configuration."
}

kill_frpc() {
    echo "Killing all frpc instances..."
    pkill -f "$FRPC_PATH"
    echo "All frpc instances killed."
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --start|-s) ACTION="start"; PORT_MAPPINGS_FILE="$2"; shift 2;;
        --serverIP) SERVER_IP="$2"; shift 2;;
        --serverPort) SERVER_PORT="$2"; shift 2;;
        --config) CONFIG_FILE="$2"; shift 2;;
        --kill|-k) ACTION="kill"; shift;;
        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac
done

if [ "$ACTION" == "start" ]; then
    start_frpc
elif [ "$ACTION" == "kill" ]; then
    kill_frpc
else
    echo "Usage: $0 --start|-s <portMappingsFile> [--serverIP <serverIP>] [--serverPort <serverPort>] [--config <configFile>] or $0 --kill|-k"
    exit 1
fi
