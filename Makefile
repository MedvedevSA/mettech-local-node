build:
	GOOS=windows GOARCH=amd64 GIN_MODE=release go build -ldflags "-H=windowsgui" -o Mettech-Explorer.exe mettech-explorer.go