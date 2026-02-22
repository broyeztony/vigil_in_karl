# syntax=docker/dockerfile:1.7

FROM golang:1.25.3-alpine AS karl-builder
ARG KARL_REF=main
RUN apk add --no-cache git
WORKDIR /src
RUN git clone https://github.com/broyeztony/Karl.git karl
WORKDIR /src/karl
RUN git checkout "$KARL_REF"
RUN go build -o /out/karl .

FROM alpine:3.20
RUN apk add --no-cache bash ca-certificates
WORKDIR /app
COPY --from=karl-builder /out/karl /usr/local/bin/karl
COPY . /app
ENV DATABASE_URL=postgres://vigil:vigil@postgres:5432/vigil?sslmode=disable
ENV TENANT_ID=00000000-0000-0000-0000-000000000001
ENV PROVIDER_TYPE=google
ENV PROVIDER_API_URL=http://mock-server:8080
CMD ["karl", "run", "cmd/discovery.k"]
