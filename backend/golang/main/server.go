package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"

	"github.com/superstes/haproxy-geoip/backend/golang/cnf"
	"github.com/superstes/haproxy-geoip/backend/golang/lookup"
)

func geoIpLookup(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("query")
	ipStr := r.URL.Query().Get("ip")
	if query == "" || ipStr == "" {
		w.WriteHeader(http.StatusBadRequest)
		io.WriteString(w, "Either 'query' or 'ip' were not provided!")
		return
	}

	ip := net.ParseIP(ipStr)
	if ip == nil {
		w.WriteHeader(http.StatusBadRequest)
		io.WriteString(w, "Provided IP is not valid!")
		return
	}

	dataStructure, lookupExists := cnf.LOOKUP[query]
	if !lookupExists || dataStructure == nil {
		w.WriteHeader(http.StatusBadRequest)
		io.WriteString(w, "Provided LOOKUP is not valid!")
		return
	}

	data := lookup.FUNC[query].(func(net.IP, interface{}) interface{})(
		ip, dataStructure,
	)
	// todo: allow additional filtering to get single attributes
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
	return
}

func server() {
	http.HandleFunc("/", geoIpLookup)
	var listenAddr = fmt.Sprintf("127.0.0.1:%v", cnf.PORT)
	fmt.Println("Listening on http://" + listenAddr)
	log.Fatal(http.ListenAndServe(listenAddr, nil))
}
