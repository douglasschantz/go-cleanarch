# Build stage
FROM golang:1.23-alpine AS builder

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Copia os arquivos de dependências
COPY go.mod go.sum ./

# Baixa as dependências
RUN go mod download

# Copia o código fonte para o diretório de trabalho
COPY . .

# Compila a aplicação
RUN GOOS=linux go build -o /app/main cmd/ordersystem/main.go cmd/ordersystem/wire_gen.go

# Estágio de produção
FROM alpine:3.18

WORKDIR /app

COPY --from=builder /app/cmd/ordersystem/.env .
COPY --from=builder /app/main .

# Copy binary from builder
COPY --from=builder /app/configs ./configs

# Instalar dependências necessárias, se houver
RUN apk --no-cache add ca-certificates

# Expose ports
EXPOSE 50051
EXPOSE 8000
EXPOSE 8080

CMD ["./main"]