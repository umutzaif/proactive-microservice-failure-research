ARG BUILDPLATFORM=linux/amd64

FROM --platform=$BUILDPLATFORM golang:1.26.4-alpine@sha256:3ad57304ad93bbec8548a0437ad9e06a455660655d9af011d58b993f6f615648 AS builder
ARG TARGETOS=linux
ARG TARGETARCH=amd64
WORKDIR /src
RUN apk add --no-cache patch

COPY source/microservices-demo/src/frontend/go.mod source/microservices-demo/src/frontend/go.sum ./
RUN go mod download
COPY source/microservices-demo/src/frontend/ ./
COPY config/frontend-dns-ab/frontend-env-platform.patch /tmp/frontend-env-platform.patch
RUN patch -p1 < /tmp/frontend-env-platform.patch
RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} CGO_ENABLED=0 go build -ldflags="-s -w" -o /go/bin/frontend .

FROM gcr.io/distroless/static@sha256:9197324ba51d9cd071af8505989365c006adf9d6d2067eada25aef00abbb5278
WORKDIR /src
COPY --from=builder /go/bin/frontend /src/server
COPY source/microservices-demo/src/frontend/templates ./templates
COPY source/microservices-demo/src/frontend/static ./static
ENV GOTRACEBACK=single
EXPOSE 8080
ENTRYPOINT ["/src/server"]
