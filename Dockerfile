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
EXPOSE 3000
CMD ["serve", "-s", "web", "-l", "3000"]
