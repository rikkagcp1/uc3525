# 部署在Codesandbox的方法1

1. 注册Codesandbox账号，最好用Github的小号登录。
2. 创建并打开一个Docker容器。
3. 打开终端，可用"Ctrl + `"快捷键。
4. 使用命令下载本repo: `wget -O main.zip "<URL>"`, 其中 `<URL>` 是绿色"<> Code"按钮下面的 "Download ZIP" 的链接地址。注意，Codesandbox上的 "git clone" 不好用。
5. 运行如下命令配置工作区workspace (复制粘贴即可)：

```
unzip main.zip -d .codesandbox
REPO_ROOT=$(ls -d .codesandbox/*/)
mv $REPO_ROOT/* .codesandbox
rm -r $REPO_ROOT main.zip
(cd .codesandbox/codesandbox && chmod +x csb.sh && ./csb.sh)
```

6. 创建环境变量（Env Variables）。点击右上角的方块图标，选择 "Project settings"，即可找到环境变量设置页面。可以在此设置新的UUID（登录凭据）。新建一个名为UUID的环境变量即可。
7. 点击右上角的方块图标，然后选择 "Restart Sandbox" 。
8. 完工。


# 部署在Codesandbox的方法2

1. 在Github上Fork本项目到自己的账号或者小号（推荐）。
2. 使用该Github账号注册并登录Codesandbox。
3. 在Dashboard（登录之后的那个地方）上，点击 "Import Repository" ，然后选择刚才Fork的项目。
4. 点击右上角的方块图标，然后选择 "Project settings" （项目设置）. 在左侧的 "Repository" 页面中，取消选择 "Protect current branch" （保护分支内容）。 
5. 运行如下命令配置工作区workspace (复制粘贴即可)：
```
[ -d .codesandbox ] && rm -rf .codesandbox
mkdir -p .codesandbox && mv -n * .codesandbox/
(cd .codesandbox/codesandbox && chmod +x csb.sh && ./csb.sh)
```
6. 创建环境变量（Env Variables）。点击右上角的方块图标，选择 "Project settings"，即可找到环境变量设置页面。可以在此设置新的UUID（登录凭据）。新建一个名为UUID的环境变量即可。
7. 点击右上角的方块图标，然后选择 "Restart Branch" 。
8. 完工。


# 注意
1. 容器过一段时间会自动休眠（数据不丢失），Cloudflare 隧道的 URL 会随时改变（免费的Cloudflare通道不保证在线时间）。最好的解决方法是使用订阅 （Subscription），地址是`https://<URL>/<UUID>.txt`， 其中 <UUID> 是 x-ray 的 UUID， <URL> 是 Codesandbox 分配的 URL，可在名为 "entrypoint:8080" 的页面中找到。
2. "entrypoint.sh" 中包含 UUID 的默认值，但是处于安全原因，强烈建议使用自己生成的UUID，设置方法见上面的步骤6。
3. 官方 Warp-Cli 在 Codesandbox 不好用，会报 "Insufficient File Descriptors"。
