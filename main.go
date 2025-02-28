package main

import (
	"errors"
	"fmt"
	"io/fs"
	"log"
	"net/http"
	"os"
	"os/exec"
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

func EnrichmentRow(c *gin.Context) {
	var items []Item

	// Привязываем JSON из тела запроса к срезу Item
	if err := c.ShouldBindJSON(&items); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Проходимся по каждому элементу и выводим label и value
	for _, item := range items {
		fmt.Printf("Label: %s, Value: %v\n", item.Label, item.Value)
	}

	// Отправляем ответ клиенту
	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Данные обработаны успешно",
	})
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
