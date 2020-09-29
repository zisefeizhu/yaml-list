package main

import (
	"flag"
	"net/http"
	"os"
	"time"

	"github.com/gorilla/handlers"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/prometheus/common/version"
	log "github.com/sirupsen/logrus"
)

var ready = false
var addr = flag.String("listen-address", ":8000", "The address to listen on for HTTP requests.")

func main() {
	flag.Parse()
	log.Info("Starting presentation-gitlab-k8s application..")
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		hostname, _ := os.Hostname()
		log.Info(hostname)
		w.Write([]byte("Hello Golang In Gitlab CI!!\n"))
		w.Write([]byte("Hostname: \n"))
		w.Write([]byte("Version Info:\n"))
		w.Write([]byte(version.Print("server") + "\n"))
	})
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		if ready {
			w.WriteHeader(http.StatusOK)
			w.Write([]byte("200"))
		} else {
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte("500"))
		}
	})
	http.Handle("/metrics", promhttp.Handler())
	go func() {
		<-time.After(5 * time.Second)
		ready = true
		log.Info("Application is ready!")
	}()
	log.Info("Listen on " + *addr)
	log.Fatal(http.ListenAndServe(*addr, handlers.LoggingHandler(os.Stdout, http.DefaultServeMux)))
}