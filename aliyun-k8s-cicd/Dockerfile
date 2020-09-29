FROM golang:1.14.3-alpine as build

WORKDIR /app
COPY . /app
RUN go env -w GO111MODULE=on \
    && go env -w GOPROXY=https://goproxy.io,direct
RUN go build -o server main.go && \
    chmod +x ./server

FROM alpine:latest

WORKDIR /app
COPY --from=build /app/server /app
EXPOSE 8000
CMD ["./server"]
