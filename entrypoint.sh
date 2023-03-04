#!/usr/bin/env bash

# 定义 UUID 及 伪装路径,请自行修改.(注意:伪装路径以 / 符号开始,为避免不必要的麻烦,请不要使用特殊符号.)
UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}
VMESS_WSPATH=${VMESS_WSPATH:-'/vmess'}
VLESS_WSPATH=${VLESS_WSPATH:-'/vless'}
TROJAN_WSPATH=${TROJAN_WSPATH:-'/trojan'}
SS_WSPATH=${SS_WSPATH:-'/shadowsocks'}
sed -i "s#UUID#$UUID#g;s#VMESS_WSPATH#${VMESS_WSPATH}#g;s#VLESS_WSPATH#${VLESS_WSPATH}#g;s#TROJAN_WSPATH#${TROJAN_WSPATH}#g;s#SS_WSPATH#${SS_WSPATH}#g" config.json
sed -i "s#VMESS_WSPATH#${VMESS_WSPATH}#g;s#VLESS_WSPATH#${VLESS_WSPATH}#g;s#TROJAN_WSPATH#${TROJAN_WSPATH}#g;s#SS_WSPATH#${SS_WSPATH}#g" /etc/nginx/nginx.conf
sed -i "s#RELEASE_RANDOMNESS#${RELEASE_RANDOMNESS}#g" /etc/supervisor/conf.d/supervisord.conf

# 设置 nginx 伪装站
rm -rf /usr/share/nginx/*
wget https://gitlab.com/Misaka-blog/xray-paas/-/raw/main/mikutap.zip -O /usr/share/nginx/mikutap.zip
unzip -o "/usr/share/nginx/mikutap.zip" -d /usr/share/nginx/html
rm -f /usr/share/nginx/mikutap.zip

# 伪装 xray 执行文件
RELEASE_RANDOMNESS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)
mv xray ${RELEASE_RANDOMNESS}
wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
cat config.json | base64 > config
rm -f config.json

# 如果有设置哪吒探针三个变量,会安装。如果不填或者不全,则不会安装
[ -n "${NEZHA_SERVER}" ] && [ -n "${NEZHA_PORT}" ] && [ -n "${NEZHA_KEY}" ] && wget https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh -O nezha.sh && chmod +x nezha.sh && ./nezha.sh install_agent ${NEZHA_SERVER} ${NEZHA_PORT} ${NEZHA_KEY}

# 启用 Argo，并输出节点日志
cloudflared tunnel --url http://localhost:80 --no-autoupdate > argo.log 2>&1 &
sleep 5 && argo_url=$(cat argo.log | grep -oE "https://.*[a-z]+cloudflare.com" | sed "s#https://##")
argo_xray_vmess="vmess://$(echo -n "\
{\
\"v\": \"2\",\
\"ps\": \"Argo_xray_vmess\",\
\"add\": \"${argo_url}\",\
\"port\": \"443\",\
\"id\": \"${UUID}\",\
\"aid\": \"0\",\
\"net\": \"ws\",\
\"type\": \"none\",\
\"host\": \"${argo_url}\",\
\"path\": \"${VMESS_WSPATH}\",\
\"tls\": \"tls\",\
\"sni\": \"${argo_url}\"\
}"\
    | base64 -w 0)"
cat > arg.log << EOF
Argo VMess + ws + TLS 通用分享链接如下：
$argo_xray_vmess

Argo VLESS + ws + TLS 通用分享链接如下：
vless://${UUID}@${argo_url}:443?encryption=none&security=tls&type=ws&host=${argo_url}&path=${VLESS_WSPATH}#Argo_xray_vless

Argo Trojan + ws + TLS 通用分享链接如下：
trojan://${UUID}@${argo_url}:443?security=tls&type=ws&host=${argo_url}&path=${TROJAN_WSPATH}#Argo_xray_trojan

Argo ShadowSocks + ws + TLS 配置明文如下：
服务器地址：${argo_url}"
端口：443
密码：${UUID}
加密方式：chacha20-ietf-poly1305
传输协议：ws
host：${argo_url}
path路径：${SS_WSPATH}
tls：开启

如当前 PaaS 容器支持 shell 方式连接，可使用 cat arg.log 重新查看节点链接
更多项目，请关注：小御坂的破站
EOF
cat arg.log

nginx
base64 -d config > config.json
./${RELEASE_RANDOMNESS} -config=config.json
