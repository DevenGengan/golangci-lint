# stage 1 building the code
FROM golang:1.22-alpine as builder

ARG VERSION
ARG SHORT_COMMIT
ARG DATE

COPY / /golangci
WORKDIR /golangci

# gcc is required to support cgo;
# git and mercurial are needed most times for go get`, etc.
# See https://github.com/docker-library/golang/issues/80
RUN apk --no-cache add gcc musl-dev git mercurial
RUN APP_VERSION=${VERSION#v} \
    CGO_ENABLED=0 \
    go build -trimpath -ldflags "-s -w -X main.version=$APP_VERSION -X main.commit=$SHORT_COMMIT -X main.date=$DATE" -o golangci-lint ./cmd/golangci-lint/main.go

# stage 2
FROM golang:1.22-alpine
# related to https://github.com/golangci/golangci-lint/issues/3107
ENV GOROOT /usr/local/go
# gcc is required to support cgo;
# git and mercurial are needed most times for go get`, etc.
# See https://github.com/docker-library/golang/issues/80
RUN apk --no-cache add gcc musl-dev git mercurial
# Set all directories as safe
RUN git config --global --add safe.directory '*'
# don't place it into $GOPATH/bin because Drone mounts $GOPATH as volume
COPY --from=builder /golangci/golangci-lint /usr/bin/
CMD ["golangci-lint"]
