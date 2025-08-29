FROM node:18-alpine as builder
WORKDIR /app
COPY package*.json ./
RUN npm install --legacy-peer-deps
COPY . .
ENV REACT_APP_API_URL=http://localhost:8080/api
RUN npm run build

FROM httpd:alpine
COPY --from=builder /app/build/ /usr/local/apache2/htdocs/
EXPOSE 80