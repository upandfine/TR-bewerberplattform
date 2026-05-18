# Node.js 22 LTS - offizielles schlankes Image
FROM node:22-alpine

WORKDIR /app

COPY app/package.json .
RUN npm install

COPY app/ /app/

EXPOSE 3000
CMD ["node", "server.js"]
