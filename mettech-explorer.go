package main

import (
	"errors"
	"io"
	"io/fs"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"

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

// processItems — основная функция обработки списка элементов
func processItems(items []Item) []ResponseItem {
	var responseItems []ResponseItem
	for _, item := range items {
		respItem := processSingleItem(item)
		responseItems = append(responseItems, respItem)
	}
	return responseItems
}

// processSingleItem — обработка одного элемента
func processSingleItem(item Item) ResponseItem {
	respItem := ResponseItem{
		Label: item.Label,
		Value: item.Value,
	}

	// Проверяем, является ли Value строкой
	if pathStr, ok := item.Value.(string); ok {
		// Проверяем, содержит ли строка "\" или "/"
		if strings.Contains(pathStr, "\\") || strings.Contains(pathStr, "/") {
			respItem.DirectoryEntries = processPath(pathStr)
		} else {
			respItem.DirectoryEntries = nil
		}
	} else {
		respItem.DirectoryEntries = nil
	}

	return respItem
}

// processPath — проверка пути и получение данных о директории
func processPath(pathStr string) *[]DirectoryEntry {
	info, err := os.Stat(pathStr)
	if err != nil || !info.IsDir() {
		log.Printf("Путь \"%s\" не существует или не является директорией: \"%v\"", pathStr, err)
		return nil
	}

	return readDirectoryEntries(pathStr)
}

// readDirectoryEntries — чтение содержимого директории
func readDirectoryEntries(pathStr string) *[]DirectoryEntry {
	entries, err := os.ReadDir(pathStr)
	if err != nil {
		log.Printf("Ошибка чтения директории \"%s\": \"%v\"", pathStr, err)
		return nil
	}

	var dirEntries []DirectoryEntry
	for _, entry := range entries {
		dirEntries = append(dirEntries, createDirectoryEntry(pathStr, entry))
	}
	return &dirEntries
}

// createDirectoryEntry — создание записи о файле/папке
func createDirectoryEntry(pathStr string, entry os.DirEntry) DirectoryEntry {
	entryPath := filepath.Join(pathStr, entry.Name())
	return DirectoryEntry{
		Path:  entryPath,
		IsDir: entry.IsDir(),
	}
}

func EnrichmentRow(c *gin.Context) {
	var items []Item

	// Привязываем JSON из тела запроса к срезу Item
	if err := c.ShouldBindJSON(&items); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, processItems(items))
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
	gin.SetMode(gin.ReleaseMode)

	// Открываем файл для логов
	logFile, err := os.OpenFile("./.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		panic("Не удалось открыть файл логов: " + err.Error())
	}
	defer logFile.Close()

	// Настраиваем многоцелевой вывод: stdout + файл
	mw := io.MultiWriter(os.Stdout, logFile)
	log.SetOutput(mw) // Устанавливаем логгер для пакета log
	gin.DefaultWriter = mw

	r := gin.New()

	// Добавляем middleware для логирования
	r.Use(gin.LoggerWithWriter(mw))
	r.Use(gin.Recovery()) // Для обработки паник
	r.Use(cors.Default())

	r.Static("/static", "./static")
	r.POST("/exec/explorer", PostExecExplorer)
	r.POST("/EnrichmentRow", EnrichmentRow)

	log.Printf("Starting server")
	if err := r.Run(Addr); err != nil {
		log.Printf("Error: %v", err)
	}
}
