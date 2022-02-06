FROM node

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 80

ENV MONGODB_USERNAME=tester
ENV MONGODB_PASSWORD=aN1NOlhZNa9pKU3T
ENV MONGODB_URL=cluster0.grs4c.mongodb.net
ENV MONGODB_NAME=goals-dev

CMD ["npm", "start"]