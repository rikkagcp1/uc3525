# Delete ALL images
`docker rmi -f $(docker images -aq)`

# Build image
`docker build -t uc3525 .`

# Run the image in a one-time container and expose port 8080 on the host
`docker run --rm --name uc3525 -p 0.0.0.0:8080:8080/tcp -it uc3525`

# Attach to the console of the container
`docker exec -it uc3525 /bin/bash`
