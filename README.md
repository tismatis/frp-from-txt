# frp-launcher
An script for autosetup frp using an .csv file.

The installer can create an service that will auto boot. 
`bash -c "$(wget -qLO - https://github.com/tismatis/frp-launcher/raw/main/misc/install.sh)"`
The installer is based on the work of https://github.com/tteck

You can create an config.toml that will contains serverAddr & serverPort.
Frp-Launcher gonna take these settings by default.

The format of the port mapping file is protocol,targetIp,targetPort,remotePort