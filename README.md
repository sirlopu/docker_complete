# Docker & Kubernetes Course Notes
--------
https://www.udemy.com/course/docker-kubernetes-the-practical-guide/

--------
## Section 1-4

#using named volumes (persistent)
docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback feedback-node:volumes

#using bind mounts (bind local app folder with container app folder) -- including anynomous volume to present overwriting protected folders (node_modules) 
docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback -v "D:\vscode-workspace\docker_complete:/app" -v /app/node_modules feedback-node:volumes

#using bind mounts adding read-only on volume :ro
docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback -v "D:\vscode-workspace\docker_complete:/app:ro" -v /app/temp -v /app/node_modules feedback-node:volumes

#specifying env port
docker run -d -p 3000:8000 --env PORT=8000 --rm --name feedback-app -v feedback:/app/feedback -v "D:\vscode-workspace\docker_complete:/app:ro" -v /app/temp -v /app/node_modules feedback-node:env

#specifying env port using file
docker run -d -p 3000:8000 --env-file ./.env --rm --name feedback-app -v feedback:/app/feedback -v "D:\vscode-workspace\docker_complete:/app:ro" -v /app/temp -v /app/node_modules feedback-node:env

#using ARGs to for docker build
docker build -t feedback-node:dev --build-arg DEFAULT_PORT=8000 .

#localhost >>> host.docker.internal


docker run --name favorites -d --rm -p 3000:3000 favorites-node

#create network (bridge is default but can be added in the command)
docker network create --driver bridge favorites-net

    Docker also supports these alternative drivers - though you will use the "bridge" driver in most cases:

    host: For standalone containers, isolation between container and host system is removed (i.e. they share localhost as a network)

    overlay: Multiple Docker daemons (i.e. Docker running on different machines) are able to connect with each other. Only works in "Swarm" mode which is a dated / almost deprecated way of connecting multiple containers

    macvlan: You can set a custom MAC address to a container - this address can then be used for communication with that container

    none: All networking is disabled.

    Third-party plugins: You can install third-party plugins which then may add all kinds of behaviors and functionalities

    As mentioned, the "bridge" driver makes most sense in the vast majority of scenarios.

docker run -d --name mongodb --network favorites-net mongo
docker run --name favorites --network favorites-net -d --rm -p 3000:3000 favorites-node

--------
## Section 5

#81 
docker run --name mongodb --rm -d -p 27017:27017 mongo

#82
docker build -t goals-node .
docker run --name goals-backend --rm -d -p 80:80 goals-node

#83 react needs to the container to run with the "-it" option to enable interactive terminal
docker build -t goals-react .
docker run --name goals-frontend --rm -d -p 3000:3000 -it goals-react

#84
docker network create goals-net
docker run --name mongodb --rm -d --network goals-net mongo
docker build -t goals-node .
docker run --name goals-backend --rm -d --network goals-net -p 80:80 goals-node
docker build -t goals-react .
docker run --name goals-frontend --rm -d -p 3000:3000 -it goals-react

#85 add data persistence to mongodb with volumes
docker run --name mongodb -v data:/data/db --rm -d --network goals-net mongo

#add authentication to mongodb
docker run --name mongodb -v data:/data/db --rm -d --network goals-net -e MONGO_INITDB_ROOT_USERNAME=max -e MONGO_INITDB_ROOT_PASSWORD=secret mongo
node app >>  'mongodb://max:secret@mongodb:27017/course-goals?authSource=admin'

#86 volumes, bind mounts for nodejs container
added nodemon as a devdependency to backend and modify npm start script
docker run --name goals-backend -v "D:\vscode-workspace\docker_complete\backend:/app"-v logs:/app/logs -v /app/node_modules --rm -d --network goals-net -p 80:80 goals-node

docker run --name goals-backend -v "D:\vscode-workspace\docker_complete\backend:/app"-v logs:/app/logs -v /app/node_modules -e MONGODB_USERNAME=max -e MONGODB_PASSWORD=secret --rm -d --network goals-net -p 80:80 goals-node


#87 live source updates for react container
docker run -v "D:\vscode-workspace\docker_complete\frontend\src:/app/src" --name goals-frontend --rm -p 3000:3000 -it goals-react

#95-98
#detached mode
docker-compose up -d 

#force re-build images
docker-compose up --build -d 

#just to build images in docker-compose file and not start the container
docker-compose build 

docker-compose down

#and remove volumes
docker-compose down -v

--------
## Section 7

#utility containers
#run a command on a running container

docker exec -it <container_name> npm init 

#overwrite default command from an image
docke run -it node npm init 

#avoiding installing node and using container to build your node package and use bind mounts
docker run -it -v "D:\vscode-workspace\docker_complete:/app" node-util npm init

#run npm install with devdependency inside utility container to build your app on host system
docker run -it -v "D:\vscode-workspace\docker_complete:/app" mynpm install express --save

#allows to run command for a single service from yaml by service name
docker-compose run --rm npm init  

--------
### NOTE ABOUT UTILITY CONTAINERS IN LINUX

wanted to point out that on a Linux system, the Utility Container idea doesn't quite work as you describe it.  In Linux, by default Docker runs as the "Root" user, so when we do a lot of the things that you are advocating for with Utility Containers the files that get written to the Bind Mount have ownership and permissions of the Linux Root user.  (On MacOS and Windows10, since Docker is being used from within a VM, the user mappings all happen automatically due to NFS mounts.)

So, for example on Linux, if I do the following (as you described in the course):

Dockerfile -----

FROM node:14-slim
WORKDIR /app

--------

$ docker build -t node-util:perm .

$ docker run -it --rm -v $(pwd):/app node-util:perm npm init

...

$ ls -la

total 16

drwxr-xr-x  3 scott scott 4096 Oct 31 16:16 ./

drwxr-xr-x 12 scott scott 4096 Oct 31 16:14 ../

drwxr-xr-x  7 scott scott 4096 Oct 31 16:14 .git/

-rw-r--r--  1 root  root   202 Oct 31 16:16 package.json

You'll see that the ownership and permissions for the package.json file are "root".  But, regardless of the file that is being written to the Bind Mounted volume from commands emanating from within the docker container, e.g. "npm install", all come out with "Root" ownership.

-------

Solution 1:  Use  predefined "node" user (if you're lucky)

There is a lot of discussion out there in the docker community (devops) about security around running Docker as a non-privileged user (which might be a good topic for you to cover as a video lecture - or maybe you have; I haven't completed the course yet).  The Official Node.js Docker Container provides such a user that they call "node". 

https://github.com/nodejs/docker-node/blob/master/Dockerfile-slim.template

FROM debian:name-slim
RUN groupadd --gid 1000 node \
         && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

Luckily enough for me on my local Linux system, my "scott" uid:gid is also 1000:1000 so, this happens to map nicely to the "node" user defined within the Official Node Docker Image.

So, in my case of using the Official Node Docker Container, all I need to do is make sure I specify that I want the container to run as a non-Root user that they make available.  To do that, I just add:

Dockerfile -----

FROM node:14-slim
USER node
WORKDIR /app

--------

If I rebuild my Utility Container in the normal way and re-run "npm init", the ownership of the package.json file is written as if "scott" wrote the file.

$ ls -la

total 12

drwxr-xr-x  2 scott scott 4096 Oct 31 16:23 ./

drwxr-xr-x 13 scott scott 4096 Oct 31 16:23 ../

-rw-r--r--  1 scott scott 204 Oct 31 16:23 package.json

------------

Solution 2:  Remove the predefined "node" user and add yourself as the user

However, if the Linux user that you are running as is not lucky to be mapped to 1000:1000, then you can modify the Utility Container Dockerfile to remove the predefined "node" user and add yourself as the user that the container will run as:

-------

FROM node:14-slim

RUN userdel -r node

ARG USER_ID

ARG GROUP_ID

RUN addgroup --gid $GROUP_ID user

RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID user

USER user

WORKDIR /app

-------

And then build the Docker image using the following (which also gives you a nice use of ARG):

$ docker build -t node-util:cliuser --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) .



And finally running it with:

$ docker run -it --rm -v $(pwd):/app node-util:cliuser npm init

$ ls -la

total 12

drwxr-xr-x  2 scott scott 4096 Oct 31 16:54 ./

drwxr-xr-x 13 scott scott 4096 Oct 31 16:23 ../

-rw-r--r--  1 scott scott  202 Oct 31 16:54 package.json



Reference to Solution 2 above: https://vsupalov.com/docker-shared-permissions/



Keep in mind that this image will not be portable, but for the purpose of the Utility Containers like this, I don't think this is an issue at all for these "Utility Containers"

--------

## Section 8

#build laravel project
docker-compose run --rm composer create-project --prefer-dist laravel/laravel .

start up specific services
docker-compose up -d server php mysql

#force recreate images if something changed
docker-compose up -d --build server 

docker-compose run --rm artisan migrate

if you run into an issue with QueryException, do this:

docker-compose run --rm artisan cache:clear
docker-compose run --rm artisan config:cache
docker-compose run --rm artisan view:clear
docker-compose run --rm artisan route:clear
docker-compose run --rm artisan config:clear

**Issue:** Permission denied when Writing to logs in server image

**Fix:** Added the following bind mounts to server service in docker-compose.yaml

      - ./src:/var/www/html:delegated
      - ./src:/var/www/html/storage/logs
      - ./src:/var/www/html/storage/framework/sessions
      - ./src:/var/www/html/storage/framework/views
      - ./src:/var/www/html/storage/framework/cache

## Using AMI Linux image

    sudo amazon-linux-extras install docker
    sudo service docker start

Other docker installation options: https://docs.docker.com/engine/install/

docker pull sirlopug/node-example-1
sudo docker run -d --rm -p 80:80 sirlopug/node-example-1


