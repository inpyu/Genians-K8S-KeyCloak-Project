BINARY_NAME=client

all: build

build: deps
	go build -o ${BINARY_NAME} client.go

deps: go.mod
	go mod tidy

go.mod:
	go mod init client

clean:
	go clean
	rm -f ${BINARY_NAME}
