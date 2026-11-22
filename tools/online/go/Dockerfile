FROM golang:1.23-alpine AS build
WORKDIR /src
COPY go.mod go.sum* ./
RUN go mod download
COPY relay.go .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /relay .

FROM gcr.io/distroless/static-debian12
COPY --from=build /relay /relay
EXPOSE 8765
USER nonroot
ENTRYPOINT ["/relay", "-addr", ":8765"]
