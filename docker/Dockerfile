# Build stage
FROM golang:1.23.1-alpine
RUN mkdir /app
ADD . /app
WORKDIR /app
ENV APP_HOME /cmd/ordersystem
RUN mkdir -p "$APP_HOME"

WORKDIR "$APP_HOME"
RUN go build -o main ./cmd/ordersystem
EXPOSE 5000
CMD ["cmd/ordersystem/main"]