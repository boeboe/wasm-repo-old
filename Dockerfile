# Build stage
FROM golang:1.21 AS builder
WORKDIR /app
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o wasm-repo .

# Start from scratch for a tiny image
FROM scratch
WORKDIR /root/
COPY --from=builder /app/wasm-repo .
EXPOSE 8080
CMD ["./wasm-repo"]
