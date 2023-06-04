#!/bin/bash

# Comment out the entry point in the Dockerfile
# Otherwise Codesandbox wont like our container
sed -i '/^ENTRYPOINT/s/^/#/' ../Dockerfile

# Disable listening on port 80 in nginx.conf
# Codesandbox does not allow you to use lower ports like 22 and 80.
# Nginx will crash with "Insufficient Privilege" if "nginx.conf" tell it to listen on port 80.
sed -i '/^[[:blank:]]*listen[[:blank:]]*80;/d' ../nginx.conf
sed -i '/^[[:blank:]]*listen[[:blank:]]*\[::\]:80;/d' ../nginx.conf

# Move "tasks.json" to its correct location
# Codesandbox does not like Dockerfile's ENTRYPOINT, we have to define another one in "tasks.json".
cp -v ./tasks.json ../
