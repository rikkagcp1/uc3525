#!/usr/bin/env bash

# This script only runs when the server is setup for the first time.

# The prefix of the entries in the subscription
DISPLAY_NAME=${DISPLAY_NAME:-'Argo_xray_'}

# 定义 UUID 及 伪装路径,请自行修改.(注意:伪装路径以 / 符号开始,为避免不必要的麻烦,请不要使用特殊符号.)
UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}
VMESS_WSPATH=${VMESS_WSPATH:-'/vmess'}
VMESS_WARP_WSPATH=${VMESS_WARP_WSPATH:-'/vmess_warp'}
VLESS_WSPATH=${VLESS_WSPATH:-'/vless'}
VLESS_WARP_WSPATH=${VLESS_WARP_WSPATH:-'/vless_warp'}
TROJAN_WSPATH=${TROJAN_WSPATH:-'/trojan'}
TROJAN_WARP_WSPATH=${TROJAN_WARP_WSPATH:-'/trojan_warp'}
SS_WSPATH=${SS_WSPATH:-'/shadowsocks'}
SS_WARP_WSPATH=${SS_WARP_WSPATH:-'/shadowsocks_warp'}

VAR_NAMES=("UUID" "VMESS_WSPATH" "VMESS_WARP_WSPATH" "VLESS_WSPATH" "VLESS_WARP_WSPATH" "TROJAN_WSPATH" "TROJAN_WARP_WSPATH" "SS_WSPATH" "SS_WARP_WSPATH" "DISPLAY_NAME" "ARGO_AUTH" "AGENT")

# Store the settings ------------------------------------------
VAR_STORAGE="env_vars.sh"
echo -e '#!/bin/bash\n' > "$VAR_STORAGE"

# Store the VAR_NAMES array
echo -ne '#!/bin/bash\nVAR_NAMES=(' > "$VAR_STORAGE"
for var_name in "${VAR_NAMES[@]}"; do
    echo -n " '$var_name'" >> "$VAR_STORAGE"
done
echo ' )' >> "$VAR_STORAGE"

# Store the each key-value pair
for var_name in "${VAR_NAMES[@]}"; do
    # Write the variable name and its value to the output file
    echo "${var_name}='${!var_name}'" >> "$VAR_STORAGE"
done
# -------------------------------------------------------------

source substitution.sh

# Update keys and restart ssh servers
KEYS_FILE="/root/.ssh/authorized_keys"
echo ${SSH_PUBKEY} > ${KEYS_FILE}
echo ${SSH_PUBKEY2} >> ${KEYS_FILE}
echo ${SSH_PUBKEY3} >> ${KEYS_FILE}
echo ${SSH_PUBKEY4} >> ${KEYS_FILE}
/etc/init.d/ssh restart
/etc/init.d/dropbear restart

# Setup Nginx and website
# rm /usr/share/nginx/html/*${UUID}*
# rm /usr/share/nginx/html/cf.txt
perform_variable_substitution "${VAR_NAMES[@]}" < template_nginx.conf > /etc/nginx/nginx.conf

# Hide xray executable
RELEASE_RANDOMNESS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)
[ -f "exec.txt" ] && RELEASE_RANDOMNESS=$(<exec.txt tr -d '\n') || echo -n $RELEASE_RANDOMNESS > exec.txt
[ -f "executable" ] && mv executable ${RELEASE_RANDOMNESS}
cat template_config.base64 | base64 --decode | perform_variable_substitution "${VAR_NAMES[@]}" | base64 > config.base64

# Download GeoIp data
[ -f "geoip.dat" ] && rm "geoip.dat"
[ -f "geosite.dat" ] && rm "geosite.dat"
wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat

# 启动Warp, 需要在Dockerfile中启用安装Warp官方客户端
# warp-svc &
# warp-cli register
# warp-cli set-custom-endpoint <xxx>
# warp-cli set-mode proxy
# warp-cli set-proxy-port 1080
# warp-cli connect

supervisord
