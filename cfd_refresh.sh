#!/bin/bash

# The only argument is the new tunnel URL.
ARGO_URL="$1"

source 'substitution.sh'
source 'env_vars.sh'

# 方便查找CF地址
echo $ARGO_URL > '/usr/share/nginx/html/cf.txt'
echo "!!! URL is: $ARGO_URL !!!" 1>&2

# 输出vmess客户端配置文件到$UUID.json
perform_variable_substitution ${VAR_NAMES[@]} 'ARGO_URL' < template_client_config.json > "/usr/share/nginx/html/$UUID.json"

# 生成qr码以及网页
vmlink=$(echo -e '\x76\x6d\x65\x73\x73')://$(echo -n "{\"v\":\"2\",\"ps\":\"${DISPLAY_NAME}vmess\",\"add\":\"$ARGO_URL\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$ARGO_URL\",\"path\":\"$VMESS_WSPATH?ed=2048\",\"tls\":\"tls\"}" | base64 -w 0)
vmlink_warp=$(echo -e '\x76\x6d\x65\x73\x73')://$(echo -n "{\"v\":\"2\",\"ps\":\"${DISPLAY_NAME}vmess(WARP)\",\"add\":\"$ARGO_URL\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$ARGO_URL\",\"path\":\"$VMESS_WARP_WSPATH?ed=2048\",\"tls\":\"tls\"}" | base64 -w 0)
vllink=$(echo -e '\x76\x6c\x65\x73\x73')"://"$UUID"@"$ARGO_URL":443?encryption=none&security=tls&type=ws&host="$ARGO_URL"&path="$VLESS_WSPATH"?ed=2048#${DISPLAY_NAME}vless"
vllink_warp=$(echo -e '\x76\x6c\x65\x73\x73')"://"$UUID"@"$ARGO_URL":443?encryption=none&security=tls&type=ws&host="$ARGO_URL"&path="$VLESS_WARP_WSPATH"?ed=2048#${DISPLAY_NAME}vless(WARP)"
trlink=$(echo -e '\x74\x72\x6f\x6a\x61\x6e')"://"$UUID"@"$ARGO_URL":443?security=tls&type=ws&host="$ARGO_URL"&path="$TROJAN_WSPATH"?ed2048#${DISPLAY_NAME}trojan"
trlink_warp=$(echo -e '\x74\x72\x6f\x6a\x61\x6e')"://"$UUID"@"$ARGO_URL":443?security=tls&type=ws&host="$ARGO_URL"&path="$TROJAN_WARP_WSPATH"?ed2048#${DISPLAY_NAME}trojan(WARP)"

# 产生订阅
echo -e "$vmlink\n$vmlink_warp\n$vllink\n$vllink_warp\n$trlink\n$trlink_warp" | base64 -w 0 > /usr/share/nginx/html/$UUID.txt

perform_variable_substitution ${VAR_NAMES[@]} 'ARGO_URL' 'vmlink' 'vmlink_warp' 'vllink' 'vllink_warp' 'trlink' 'trlink_warp' < template_webpage.html > "/usr/share/nginx/html/$UUID.html"
