# Deploy on Codesandbox

1. Register an account, I would recommend that you register another Github account use it as the login credential.
2. Create a Docker container and open it.
3. Launch a terminal on Codesandbox.
4. Download this repo as an archive by running `wget -O main.zip "<URL>"`, where `<URL>` is the link of "Download ZIP" under the green "<> Code" button. Note that "git clone" does not work on Codesandbox's console.
5. Run these commands (Just copy and paste) to setup the workspace:

```
unzip main.zip -d .codesandbox
REPO_ROOT=$(ls -d .codesandbox/*/)
mv $REPO_ROOT/* .codesandbox
rm -r $REPO_ROOT main.zip
(cd .codesandbox/codesandbox && ./csb.sh)
```

6. Customize by creating "Env Variables". Click on square on the top-right corner of the page, then go to "Project settings". You can assign a new UUID for x-ray here by creating an "Env Variables" named "UUID".
7. Restart the container. Click on square on the top-right corner of the page, then choose "Restart Sandbox".
8. Done.


# Note
1. The container will sleep automatically after a while, and the Cloudflare tunnel URL may change at anytime. So the best practice is to use the subscription, the URL is `https://<CONTAINER_MAGIC_NUMBER>-8080.csb.app/<UUID>.txt`, where <UUID> is the UUID used by x-ray, <CONTAINER_MAGIC_NUMBER> is usually a string made of numbers and lower-case letters, that is the last part of your container name after the final dash.
2. The UUID has some default value. See "entrypoint.sh". But for security reasons, it is highly recommended to change that. See step 6 above.
3. Official Warp-Cli does not work on Codesandbox due to "Insufficient File Descriptors".
