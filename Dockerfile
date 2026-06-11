FROM golang:1.19.0-alpine AS build

RUN apk --update add \
      ca-certificates \
      git

RUN mkdir /aws-sigv4-proxy
WORKDIR /aws-sigv4-proxy
COPY  . .

RUN go env -w GOPROXY=direct

RUN CGO_ENABLED=0 GOOS=linux go build ./cmd/aws-sigv4-proxy

FROM alpine:3

RUN apk add --no-cache ca-certificates

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /aws-sigv4-proxy/aws-sigv4-proxy /usr/local/bin/aws-sigv4-proxy

ARG APP_UID=1001
ARG APP_GID=1001
RUN addgroup -g "${APP_GID}" -S app \
  && adduser -u "${APP_UID}" -S -G app -h /home/app -D app \
  && chmod +x /usr/local/bin/aws-sigv4-proxy

ENTRYPOINT ["/usr/local/bin/aws-sigv4-proxy"]

USER app:app
