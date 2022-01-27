FROM node:14

WORKDIR /app

COPY package.json /app

RUN npm install 

COPY . /app

ENV PORT 80

EXPOSE $PORT

# VOLUME [ "/app/node_modules "] >> anynomous volume

# CMD ["node", "server.js"]
CMD [ "npm", "start" ]