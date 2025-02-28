package main

import (
	"errors"
	"io/fs"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

const (
	Addr = "127.0.0.1:2003"
)

type ExplorerArgs struct {
	Path string `json:"path" binding:"required"`
}

func IsPathExists(path string) (bool, error) {
	_, err := os.Stat(path)
	if err == nil {
		return true, nil
	}
	if errors.Is(err, fs.ErrNotExist) {
		return false, nil
	}
	return false, err
}

type Item struct {
	Label string      `json:"label"`
	Value interface{} `json:"value"`
}

// DirectoryEntry представляет запись директории
type DirectoryEntry struct {
	Path  string `json:"path"`
	IsDir bool   `json:"isDir"`
}

// ResponseItem представляет элемент с дополнительными данными о директории
type ResponseItem struct {
	Label            string            `json:"label"`
	Value            interface{}       `json:"value"`
	DirectoryEntries *[]DirectoryEntry `json:"directoryEntries"`
}

func EnrichmentRow(c *gin.Context) {
	var items []Item

	// Привязываем JSON из тела запроса к срезу Item
	if err := c.ShouldBindJSON(&items); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var responseItems []ResponseItem

	for _, item := range items {
		respItem := ResponseItem{
			Label: item.Label,
			Value: item.Value,
		}

		// Проверяем, является ли Value строкой
		if pathStr, ok := item.Value.(string); ok {
			// Проверяем, существует ли путь и является ли он директорией
			info, err := os.Stat(pathStr)
			if err == nil && info.IsDir() {
				entries, err := os.ReadDir(pathStr)
				if err == nil {
					var dirEntries []DirectoryEntry
					for _, entry := range entries {
						entryPath := filepath.Join(pathStr, entry.Name())
						dirEntries = append(dirEntries, DirectoryEntry{
							Path:  entryPath,
							IsDir: entry.IsDir(),
						})
					}
					respItem.DirectoryEntries = &dirEntries
				} else {
					// Если ошибка при чтении директории, устанавливаем nil
					respItem.DirectoryEntries = nil
				}
			} else {
				// Если путь не существует или не директория, устанавливаем nil
				respItem.DirectoryEntries = nil
			}
		} else {
			// Если Value не строка, устанавливаем nil
			respItem.DirectoryEntries = nil
		}

		responseItems = append(responseItems, respItem)
	}

	c.JSON(http.StatusOK, responseItems)
}

func PostExecExplorer(c *gin.Context) {
	var command string
	var json ExplorerArgs

	if err := c.ShouldBindJSON(&json); err != nil {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
		return
	}
	exists, err := IsPathExists(json.Path)
	if !exists || err != nil {
		errStr := ""
		if err != nil {
			errStr = err.Error()
		}
		c.JSON(http.StatusNotFound, gin.H{
			"message": "Path Not Exists",
			"error":   errStr,
		})
		return
	}

	if runtime.GOOS == "windows" {
		command = "explorer"
	} else {
		command = "xdg-open"
	}

	output, err := exec.Command(command, json.Path).Output()
	c.JSON(200, gin.H{
		"output":     output,
		"output.err": err,
	})
}

func main() {
	r := gin.Default()

	r.Use(cors.Default())
	r.Static("/static", "./static")
	r.POST("/exec/explorer", PostExecExplorer)
	r.POST("/EnrichmentRow", EnrichmentRow)

	if err := r.Run(Addr); err != nil {
		log.Printf("Error: %v", err)
	}
}
