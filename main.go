package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

var uploadDir string

// Initialize the server, define routes and listen for requests.
func main() {
	initUploadDirectory()

	http.HandleFunc("/wasm-plugins/", handleWasmPluginsRequest)
	http.HandleFunc("/list", listFiles)

	fmt.Println("Server started on :8080")
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		fmt.Printf("Error starting server: %v\n", err)
		os.Exit(1)
	}
}

// Initialize the upload directory from environment or use default.
func initUploadDirectory() {
	uploadDir = os.Getenv("UPLOAD_DIR")
	if uploadDir == "" {
		uploadDir = "./uploads" // Default if the environment variable is not set
	}

	if info, err := os.Stat(uploadDir); err == nil {
		if !info.IsDir() {
			fmt.Printf("%v already exists but is not a directory\n", uploadDir)
			os.Exit(1)
		}
		return
	} else if os.IsNotExist(err) {
		err := os.MkdirAll(uploadDir, 0755)
		if err != nil {
			fmt.Printf("Error creating upload directory: %v\n", err)
			os.Exit(1)
		}
	} else {
		fmt.Printf("Error checking upload directory: %v\n", err)
		os.Exit(1)
	}
}

// Handle requests related to wasm plugins: upload and download.
func handleWasmPluginsRequest(w http.ResponseWriter, r *http.Request) {
	filename := strings.TrimPrefix(r.URL.Path, "/wasm-plugins/")
	filePath := filepath.Join(uploadDir, filename)

	switch r.Method {
	case http.MethodGet:
		fmt.Printf("Attempting to download file: %s\n", filename)
		http.ServeFile(w, r, filePath)

	case http.MethodPost:
		err := saveUploadedFile(r, filePath)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		fmt.Printf("Successfully uploaded file: %s\n", filename)
		_, err = w.Write([]byte("File uploaded successfully!"))
		if err != nil {
			http.Error(w, "Failed to write response: "+err.Error(), http.StatusInternalServerError)
			return
		}

	default:
		http.Error(w, "Unsupported method", http.StatusMethodNotAllowed)
	}
}

// Save the uploaded file to the server.
func saveUploadedFile(r *http.Request, filePath string) error {
	uploadedFile, _, err := r.FormFile("file")
	if err != nil {
		return fmt.Errorf("failed to read uploaded file: %v", err)
	}
	defer uploadedFile.Close()

	if _, err := os.Stat(filePath); !os.IsNotExist(err) {
		fmt.Println("file already exists, overwriting:", filePath)
	}

	dstFile, err := os.Create(filePath)
	if err != nil {
		return fmt.Errorf("failed to save uploaded file: %v", err)
	}
	defer dstFile.Close()

	_, err = io.Copy(dstFile, uploadedFile)
	if err != nil {
		return fmt.Errorf("failed to save uploaded file: %v", err)
	}

	return nil
}

// List the files available for download.
func listFiles(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Only GET is supported", http.StatusMethodNotAllowed)
		return
	}

	files, err := os.ReadDir(uploadDir)
	if err != nil {
		http.Error(w, "Failed to list files: "+err.Error(), http.StatusInternalServerError)
		return
	}

	for _, file := range files {
		if !file.IsDir() {
			fmt.Fprintln(w, file.Name())
		}
	}
}
