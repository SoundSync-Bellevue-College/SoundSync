package main

import (
	"context"
	"log"
	"net/http"
	"os/signal"
	"syscall"

	_ "github.com/joho/godotenv/autoload"
	"soundsync/backend/internal/app"
)

func main() {
	runtime, err := app.New()
	if err != nil {
		log.Fatal(err)
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	go func() {
		<-ctx.Done()
		_ = runtime.Shutdown(context.Background())
	}()

	log.Printf("server listening on %s", runtime.Server.Addr)
	if err := runtime.Server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatal(err)
	}
}
