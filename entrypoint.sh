#!/usr/bin/env bash

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

perform_substitutions() {
    [ -f "$2" ] && rm "$2"
    cp "$1" "$2"
    sed -i "s#UUID#$UUID#g;s#VMESS_WSPATH#${VMESS_WSPATH}#g;s#VMESS_WARP_WSPATH#${VMESS_WARP_WSPATH}#g;s#VLESS_WSPATH#${VLESS_WSPATH}#g;s#VLESS_WARP_WSPATH#${VLESS_WARP_WSPATH}#g;s#TROJAN_WSPATH#${TROJAN_WSPATH}#g;s#TROJAN_WARP_WSPATH#${TROJAN_WARP_WSPATH}#g;s#SS_WSPATH#${SS_WSPATH}#g;s#SS_WARP_WSPATH#${SS_WARP_WSPATH}#g" "$2"
}

perform_substitutions template_config.json config.json
perform_substitutions template_nginx.conf /etc/nginx/nginx.conf

# 配置并启动SSH服务器
KEYS_FILE="/root/.ssh/authorized_keys"
mkdir -p /root/.ssh
echo ${SSH_PUBKEY:-'dummy'} > ${KEYS_FILE}
echo ${SSH_PUBKEY2:-'dummy'} > ${KEYS_FILE}
echo ${SSH_PUBKEY3:-'dummy'} > ${KEYS_FILE}
echo ${SSH_PUBKEY4:-'dummy'} > ${KEYS_FILE}
chmod 644 ${KEYS_FILE}
/etc/init.d/ssh restart

# 设置 nginx 伪装站
rm -rf /usr/share/nginx/*
unzip -o "./mikutap.zip" -d /usr/share/nginx/html

# 伪装 xray 执行文件
RELEASE_RANDOMNESS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)
[ -f "exec.txt" ] && RELEASE_RANDOMNESS=$(<exec.txt tr -d '\n') || echo -n $RELEASE_RANDOMNESS > exec.txt
mv xray ${RELEASE_RANDOMNESS}
[ -f "geoip.dat" ] && rm "geoip.dat"
[ -f "geosite.dat" ] && rm "geosite.dat"
wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
cat config.json | base64 > config
rm -f config.json

# 如果有设置哪吒探针三个变量,会安装。如果不填或者不全,则不会安装
[ -n "${NEZHA_SERVER}" ] && [ -n "${NEZHA_PORT}" ] && [ -n "${NEZHA_KEY}" ] && wget https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh -O nezha.sh && chmod +x nezha.sh && ./nezha.sh install_agent ${NEZHA_SERVER} ${NEZHA_PORT} ${NEZHA_KEY}

# 启用 Argo，并输出节点日志
cloudflared tunnel --url http://localhost:80 --no-autoupdate > argo.log 2>&1 &
sleep 5 && argo_url=$(cat argo.log | grep -oE "https://.*[a-z]+cloudflare.com" | sed "s#https://##")

# 方便查找CF地址
echo $argo_url > /usr/share/nginx/html/cf.txt

# 启动Warp, 需要在Dockerfile中启用安装Warp官方客户端
# warp-svc &
# warp-cli register
# warp-cli set-custom-endpoint <xxx>
# warp-cli set-mode proxy
# warp-cli set-proxy-port 1080
# warp-cli connect

# 输出v2ray vmess客户端配置文件到$UUID.json
cat > /usr/share/nginx/html/$UUID.json<<-EOF
{
  "log": {
    "loglevel": "debug"
  },
  "inbounds": [
    {
      "port": 1080,
      "protocol": "socks",
      "sniffing": {
        "enabled": true,
        "destOverride": [ "http", "tls" ]
      },
      "settings": {
        "auth": "noauth",
        "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "$argo_url",
            "port": 443,
            "users": [
              {
                "id": "$UUID",
                "alterId": 0
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "wsSettings": {
          "path": "/vmess"
        }
      }
    }
  ]
}
EOF

# 生成qr码以及网页
vmlink=$(echo -e '\x76\x6d\x65\x73\x73')://$(echo -n "{\"v\":\"2\",\"ps\":\"${DISPLAY_NAME}vmess\",\"add\":\"$argo_url\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$argo_url\",\"path\":\"$VMESS_WSPATH?ed=2048\",\"tls\":\"tls\"}" | base64 -w 0)
vmlink_warp=$(echo -e '\x76\x6d\x65\x73\x73')://$(echo -n "{\"v\":\"2\",\"ps\":\"${DISPLAY_NAME}vmess\",\"add\":\"$argo_url\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$argo_url\",\"path\":\"$VMESS_WARP_WSPATH?ed=2048\",\"tls\":\"tls\"}" | base64 -w 0)
vllink=$(echo -e '\x76\x6c\x65\x73\x73')"://"$UUID"@"$argo_url":443?encryption=none&security=tls&type=ws&host="$argo_url"&path="$VLESS_WSPATH"?ed=2048#${DISPLAY_NAME}vless"
vllink_warp=$(echo -e '\x76\x6c\x65\x73\x73')"://"$UUID"@"$argo_url":443?encryption=none&security=tls&type=ws&host="$argo_url"&path="$VLESS_WARP_WSPATH"?ed=2048#${DISPLAY_NAME}vless"
trlink=$(echo -e '\x74\x72\x6f\x6a\x61\x6e')"://"$UUID"@"$argo_url":443?security=tls&type=ws&host="$argo_url"&path="$TROJAN_WSPATH"?ed2048#${DISPLAY_NAME}trojan"
trlink_warp=$(echo -e '\x74\x72\x6f\x6a\x61\x6e')"://"$UUID"@"$argo_url":443?security=tls&type=ws&host="$argo_url"&path="$TROJAN_WARP_WSPATH"?ed2048#${DISPLAY_NAME}trojan"

# 产生订阅
echo -e "$vmlink\n$vmlink_warp\n$vllink\n$vllink_warp\n$trlink\n$trlink_warp" | base64 -w 0 > /usr/share/nginx/html/$UUID.txt

qrencode -o /usr/share/nginx/html/M$UUID.png $vmlink
qrencode -o /usr/share/nginx/html/MW$UUID.png $vmlink_warp
qrencode -o /usr/share/nginx/html/L$UUID.png $vllink
qrencode -o /usr/share/nginx/html/LW$UUID.png $vllink_warp
qrencode -o /usr/share/nginx/html/T$UUID.png $trlink
qrencode -o /usr/share/nginx/html/TW$UUID.png $trlink_warp

cat > /usr/share/nginx/html/$UUID.html<<-EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>Argo-xray-paas</title>
    <style type="text/css">
        body {
            font-family: Geneva, Arial, Helvetica, san-serif;
        }

        div {
            margin: 0 auto;
            text-align: left;
            white-space: pre-wrap;
            word-break: break-all;
            max-width: 80%;
            margin-bottom: 10px;
        }
    </style>
</head>
<body bgcolor="#FFFFFF" text="#000000">
    <div><font color="#009900"><b>VMESS协议链接(VPS出口)：</b></font></div>
    <div>$vmlink</div>
    <div><img src="/M$UUID.png"></div>
    <div><font color="#009900"><b>VMESS协议链接(Warp出口)：</b></font></div>
    <div>$vmlink_warp</div>
    <div><img src="/MW$UUID.png"></div>

    <div><font color="#009900"><b>VLESS协议链接(VPS出口)：</b></font></div>
    <div>$vllink</div>
    <div><img src="/L$UUID.png"></div>
    <div><font color="#009900"><b>VLESS协议链接(Warp出口)：</b></font></div>
    <div>$vllink_warp</div>
    <div><img src="/LW$UUID.png"></div>

    <div><font color="#009900"><b>TROJAN协议链接(VPS出口)：</b></font></div>
    <div>$trlink</div>
    <div><img src="/T$UUID.png"></div>
    <div><font color="#009900"><b>TROJAN协议链接(Warp出口)：</b></font></div>
    <div>$trlink_warp</div>
    <div><img src="/TW$UUID.png"></div>

    <div><font color="#009900"><b>SS协议明文：</b></font></div>
    <div>服务器地址：$argo_url</div>
    <div>端口：443</div>
    <div>密码：$UUID</div>
    <div>加密方式：chacha20-ietf-poly1305</div>
    <div>传输协议：ws</div>
    <div>host：$argo_url</div>
    <div>path路径：$SS_WSPATH?ed=2048</div>
    <div>path全程Warp路径：$SS_WARP_WSPATH?ed=2048</div>
    <div>TLS：开启</div>
</body>
</html>
EOF

echo $argo_url

nginx
base64 -d config > config.json
./${RELEASE_RANDOMNESS} -config=config.json
