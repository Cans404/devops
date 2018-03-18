// dns check in recovery env
// created by Cans, 20180308

package main

import (
	"fmt"
	"net"
	"time"
)

const (
	Y = string(8730)
	N = string(215)
)

func main() {
	var hosts = [13]string{"hfm.***.com",
		"***hfm01-bi",
		"***hfm02-bi",
		"***hfm03-bi",
		"***hfm03-bi",
		"***hfm04-bi",
		"***hfm05-bi",
		"hfm-scan.***.com",
		"ghfm-scan.***.com",
		"***m8fu200***",
		"***m8fu200***",
		"***hafu200***",
		"***hafu200***"}

	fmt.Println("")

	for _, host := range hosts[:7] {
		ip := dnsResolve(host)
		if ip == "10.98.***" {
			fmt.Printf("%-30s==========>>%15s [%s]\n", host, ip, Y)
		} else {
			fmt.Printf("%-30s==========>>%15s [%s]\n", host, ip, N)
		}
	}

	for _, host := range hosts[7:] {
		ip := dnsResolve(host)
		if ip == "10.98.***" {
			fmt.Printf("%-30s==========>>%15s [%s]\n", host, ip, Y)
		} else {
			fmt.Printf("%-30s==========>>%15s [%s]\n", host, ip, N)
		}
	}

	fmt.Println("")
}

func dnsResolve(host string) (ip string) {
	dur, _ := time.ParseDuration("5s")
	conn, _ := net.DialTimeout("ip4:icmp", host, dur)
	addr := conn.RemoteAddr()
	rte := addr.String()
	return rte
}

