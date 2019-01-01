package main

import (
	"net/http"
)

func main() {
	FSDir := http.FileServer(http.Dir("/root/Cans"))
	http.Handle("/fileserver/", http.StripPrefix("/fileserver/", FSDir))

	http.ListenAndServe(":12580", nil)
}
