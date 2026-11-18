FROM golang:1.22 AS build
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -mod=mod -o /notes .

FROM gcr.io/distroless/static
COPY --from=build /notes /notes
ENV PORT=8080
EXPOSE 8080
USER nonroot
ENTRYPOINT ["/notes"]
