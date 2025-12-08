FROM ghcr.io/cirruslabs/flutter:latest as build

WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get
COPY . .

# Habilitar web y compilar
RUN flutter config --enable-web && flutter build web --release

FROM node:18-alpine as runtime
RUN npm i -g serve
WORKDIR /app
COPY --from=build /app/build/web ./web
# Railway expone $PORT (suele ser 8080); forzamos host 0.0.0.0
ENV PORT=8080
EXPOSE ${PORT}
# serve acepta --listen PORT o --listen tcp://0.0.0.0:PORT
CMD ["sh", "-c", "serve -s web --listen tcp://0.0.0.0:${PORT}"]
