# Deploy on Codesandbox

1. Register an account, I would recommend that you register another Github account use it as the login credential.
2. Create a Docker container and open it.
3. Launch a console on Codesandbox.
4. Delete the old ".codesandbox" folder: `rm -rf .codesandbox`
5. Use "wget" command to download the archive of this repo, the link can be found on the Github page by clicking on the "Code" button, and then copy the link of "Download ZIP". Note that "git clone" does not work on Codesandbox's console.
6. Upzip the archive: `unzip main.zip`, then rename the extracted folder to `.codesandbox`.
7. Comment out the "ENTRYPOINT" line in the Dockerfile.
8. Create "tasks.json" inside ".codesandbox" with the following content:
```
{
  "setupTasks": [],
  "tasks": {
    "main": {
      "name": "main",
      "command": "/bin/bash -c \"cd /app && ./entrypoint.sh\"",
      "preview": {
        "port": 8080,
        "prLink": "direct"
      },
      "runAtStart": true
    }
  }
}
```
9. Customize by creating "Env Variables". Click on square on the top-right corner of the page, then go to "Project settings". You can assign a new UUID for x-ray here.
10. Restart the container. Click on square on the top-right corner of the page, then choose "Restart Sandbox".
11. Done.


# Note
1. The container will sleep automatically after a while, and the Cloudflare tunnel URL may change at anytime. So the best practice is to use the subscription, the URL is `https://<CONTAINER_MAGIC_NUMBER>-8080.csb.app/<UUID>.txt`, where <UUID> is the UUID used by x-ray, <CONTAINER_MAGIC_NUMBER> is usually a string made of numbers and lower-case letters, that is the last part of your container name after the final dash.
2. The UUID has some default value. See "entrypoint.sh". But for security reasons, it is highly recommended to change that. See step 9 above.
3. Warp does not work on Codesandbox, at least for now.
