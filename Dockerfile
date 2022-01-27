FROM node:14

WORKDIR /app

COPY package.json /app

RUN npm install 

COPY . /app

ARG DEFAULT_PORT=80

ENV PORT $DEFAULT_PORT

EXPOSE $PORT

# VOLUME [ "/app/node_modules "] >> anynomous volume

# CMD ["node", "server.js"]
CMD [ "npm", "start" ]