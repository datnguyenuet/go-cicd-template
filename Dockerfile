# Base image with golang installed
FROM public.ecr.aws/docker/library/golang:1.21.4 as base
WORKDIR /app/
ENV GOOS="linux"
ENV CGO_ENABLED=0

# Development image with air (Live reload for Go apps) installed
FROM base as dev
WORKDIR /app/
RUN curl -sSfL https://raw.githubusercontent.com/cosmtrek/air/master/install.sh | sh -s -- -b $(go env GOPATH)/bin
ENTRYPOINT ["air"]

# Builder image for building the Go app
FROM base as builder
ADD . /app/
WORKDIR /app/
RUN CGO_ENABLE=0 GOOS=linux go build -a -installsuffix cgo -o go-cicd .

# Final image with the Go app
FROM public.ecr.aws/docker/library/debian:buster-slim
RUN set -x && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /app/
COPY --from=builder /app/go-cicd .
ENTRYPOINT ["/app/go-cicd"]