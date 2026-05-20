# ------------------------------------------------------------
#  Stage 1: Build
# ------------------------------------------------------------
FROM node:20-alpine AS build
WORKDIR /app

COPY package.json ./
RUN npm install --no-audit --no-fund

COPY index.html vite.config.js ./
COPY src ./src

RUN npm run build

# ------------------------------------------------------------
#  Stage 2: Serve mit nginx
# ------------------------------------------------------------
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
