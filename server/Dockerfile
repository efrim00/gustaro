FROM dart:stable AS build
WORKDIR /app
COPY pubspec.yaml ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/server.dart -o /app/server

FROM debian:stable-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app/server /app/server
COPY --from=build /app/seed /app/seed
COPY --from=build /app/web /app/web
USER nobody
CMD ["/app/server"]
