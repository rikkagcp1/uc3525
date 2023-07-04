# Argo xray for PaaS

back4app可以直接克隆本项目。Codesandbox部署方式参见[codesandbox/README.md](codesandbox/README.md)，还有[中文版](codesandbox/README.zh_cn.md)。

## 项目特点

* 本项目用于在任意一家 PaaS 云服务商部署 xray ，采用的方案为 Argo + Nginx + WebSocket + VMess/Vless/Trojan/Shadowsocks + TLS
* xray 核心文件和配置文件作了“特殊处理”，每个项目都不同，大大降低被封和连坐风险
* vmess 和 vless 的 uuid 或 trojan 和 shadowsocks 的密码，路径既可以自定义，又或者使用默认值
* 集成哪吒探针，可以自由选择是否安装
* 部署完成如发现不能上网，请检查域名是否被墙，可使用生成的 Argo 节点或 Cloudflare CDN 或者 worker 解决。
* 可在支持Docker的VPS（KVM或者OpenVZ 7以上）上直接部署。

## 增强

* `https://<PaaS云服务商分配的域名>/<UUID>.html` 展示了各种配置以及客户端二维码。
* `https://<PaaS云服务商分配的域名>/<UUID>.json` 为对应的v2ray客户端文件。
* 增加订阅模式，以防止每次Cloudflare分配的域名改变。可在V2rayA和安卓上的V2rayNG中添加订阅，地址为`https://<PaaS云服务商分配的域名>/<UUID>.txt`。每次发现之前的地址不可用之后先刷新下订阅再尝试连接，如果还不行过30秒刷一次再试，因为容器启动需要时间。
* `https://<PaaS云服务商分配的域名>/cf.txt` 为最新的Cloudflare分配域名。
* 增加Cloudflared多次重试，应对Cloudflare偶尔抽风。
* 在连接路径后面增加"_warp"来使流量全程走Cloudflare Warp。
* `https://<PaaS云服务商分配的域名>/<UUID>.rootfs/`可直接下载rootfs中的内容（可在nginx.conf中删除相关段以禁用）。

### Cloudflare固定隧道

使用固定隧道需要设置ARGO_AUTH（Token，一长串Base64编码字符，可在Cloudflare官网隧道的Overview页面里找到），并在Cloudflare官网上配置一个Tunnel的Public Hostname，其服务需要指向`127.0.0.1:8080`。
如果未设置ARGO_AUTH则不启用该特性。启用固定隧道并不会禁用trycloudflare.com的域名。

固定隧道的地址为类似`https://固定通道的域名/VMESS_WSPATH`，端口，UUID等其他设置与非固定隧道的配置一样。

### 远程管理

* 增加ssh服务器，可连接至后台。该ssh服务在公网上不可见，需要以无"_warp"的路径连接到节点，然后通过代理来连接：`ssh root@127.0.0.1 -p2223 -v -o StrictHostKeyChecking=no -o ProxyCommand="/usr/bin/nc -x 127.0.0.1:1080 %h %p"`，其中127.0.0.1:1080为本地socks5服务器。
* 有两种ssh服务器，sshd监听22和2222端口，dropbear监听2223端口。如果22端口不可用则可以在ssh命令后面增加`-p 端口`来使用其他端口连接。
* ssh大多数情况下默认登录到root用户。
* ssh服务器仅支持Key的方式登录，可以设置环境变量`SSH_PUBKEY`、`SSH_PUBKEY2`、`SSH_PUBKEY3`和`SSH_PUBKEY4`，最多支持4个Key。

## 部署

* 注册任意一家 PaaS 云服务商
* 根据 PaaS 云服务商的不同绑定自己的 GitHub 账户或使用项目提供的 Actions 生成 DockerHub 镜像，严重建议小号 + 私库
* 项目可用到的变量
  | 变量名 | 是否必须 | 默认值 | 备注 |
  | ------------ | ------ | ------ | ------ |
  | UUID         | 否 | de04add9-5c68-8bab-950c-08cd5320df18 | 可在线生成 https://www.uuidgenerator.net/ |
  | ARGO_AUTH    | 否 |    | Cloudflare固定隧道的Token(一长串Base64编码字符) |
  | VMESS_WSPATH  | 否 | /vmess | 以 / 开头 |
  | VMESS_WSPATH_WARP  | 否 | /vmess_warp | 以 / 开头 |
  | VLESS_WSPATH  | 否 | /vless | 以 / 开头 |
  | VLESS_WSPATH_WARP  | 否 | /vless_warp | 以 / 开头 |
  | TROJAN_WSPATH | 否 | /trojan | 以 / 开头 |
  | TROJAN_WSPATH_WARP | 否 | /trojan_warp | 以 / 开头 |
  | SS_WSPATH     | 否 | /shadowsocks | 以 / 开头 |
  | SS_WSPATH_WARP     | 否 | /shadowsocks_warp | 以 / 开头 |
  | AGENT  | 否 |     | 哪吒探针的配置，格式为`-s <RPC服务端IP或域名>:<端口> -p <密钥Key>`，空格分格，可附加其他参数如`--tls` |

* GitHub Actions 用到的变量

  |    变量名     |      备注      |
  | ------------- | -------------- |
  |DOCKER_USERNAME|Docker Hub 用户名|
  |DOCKER_PASSWORD|Docker Hub 密码  |
  |DOCKER_REPO    |Docker Hub 仓库名|

![image](https://user-images.githubusercontent.com/116990986/211692321-34df154a-320a-448f-9abe-2efab9c53550.png)

## 鸣谢

* ifeng 的 v2ray 项目：https://github.com/hiifeng
* fscarmen2 的 argo xray 项目：https://github.com/fscarmen2

## 免责声明

* 本程序仅供学习了解, 非盈利目的，请于下载后 24 小时内删除, 不得用作任何商业用途, 文字、数据及图片均有所属版权, 如转载须注明来源。
* 使用本程序必循遵守部署免责声明。使用本程序必循遵守部署服务器所在地、所在国家和用户所在国家的法律法规, 程序作者不对使用者任何不当行为负责.

## 赞助

爱发电：https://afdian.net/a/Misaka-blog

![afdian-MisakaNo の 小破站](https://user-images.githubusercontent.com/122191366/211533469-351009fb-9ae8-4601-992a-abbf54665b68.jpg)
