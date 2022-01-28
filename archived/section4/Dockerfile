FROM node

WORKDIR /app

COPY package.json .

RUN npm install

COPY . /app

CMD ["node", "app.js"]