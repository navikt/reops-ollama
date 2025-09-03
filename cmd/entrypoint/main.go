package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"syscall"
	"time"
)

func envOr(key, def string) string {
	v := os.Getenv(key)
	if v == "" {
		return def
	}
	return v
}

func waitReady(timeout time.Duration) error {
	client := &http.Client{Timeout: 2 * time.Second}
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		resp, err := client.Get("http://localhost:11434/api/tags")
		if err == nil {
			io.Copy(io.Discard, resp.Body)
			resp.Body.Close()
			if resp.StatusCode >= 200 && resp.StatusCode < 500 {
				return nil
			}
		}
		time.Sleep(1 * time.Second)
	}
	return fmt.Errorf("timeout waiting for ollama server")
}

func runOutput(name string, args ...string) (string, error) {
	cmd := exec.Command(name, args...)
	out, err := cmd.CombinedOutput()
	return string(out), err
}

func main() {
	model := envOr("MODEL_NAME", "llama3.2:3b")
	ollamaHome := envOr("OLLAMA_HOME", "/tmp")
	// ensure directories
	os.MkdirAll(ollamaHome, 0o777)
	os.MkdirAll(ollamaHome+"/.ollama", 0o777)

	// start ollama serve in background
	cmd := exec.Command("/usr/local/bin/ollama", "serve")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Start(); err != nil {
		fmt.Fprintf(os.Stderr, "failed to start ollama: %v\n", err)
		os.Exit(1)
	}

	// wait for server
	if err := waitReady(2 * time.Minute); err != nil {
		fmt.Fprintf(os.Stderr, "server did not become ready: %v\n", err)
		// try to kill background
		_ = cmd.Process.Kill()
		cmd.Wait()
		os.Exit(1)
	}

	// check models
	out, err := runOutput("/usr/local/bin/ollama", "list")
	if err != nil {
		// if list fails, continue and attempt pull
		fmt.Fprintf(os.Stderr, "ollama list failed: %v\n", err)
	}

	if !strings.Contains(out, model) {
		fmt.Fprintf(os.Stdout, "Model %s not present, pulling...\n", model)
		pull := exec.Command("/usr/local/bin/ollama", "pull", model)
		pull.Stdout = os.Stdout
		pull.Stderr = os.Stderr
		if err := pull.Run(); err != nil {
			fmt.Fprintf(os.Stderr, "failed to pull model: %v\n", err)
			// continue; try to shutdown cleanly
		}
	} else {
		fmt.Fprintf(os.Stdout, "Model %s already present\n", model)
	}

	// stop background server
	_ = cmd.Process.Kill()
	cmd.Wait()

	// exec ollama serve in foreground
	env := os.Environ()
	argv0 := "/usr/local/bin/ollama"
	argv := []string{argv0, "serve"}
	if err := syscall.Exec(argv0, argv, env); err != nil {
		fmt.Fprintf(os.Stderr, "exec failed: %v\n", err)
		os.Exit(1)
	}
}
