// created by Cans, 20180518
// new sns interface

package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"regexp"
)

type params struct {
	App_id  string `json:"app_id"`
	Mobiles string `json:"mobiles"`
	Content string `json:"content"`
}

func httpDo(b []byte) {
	client := &http.Client{}

	restParam := bytes.NewReader(b)
	restURL := "https://apigw.***.com/api/sns/sms/send/v2"
	req, _ := http.NewRequest("POST", restURL, restParam)

	req.Header.Set("Content-Type", "application/json;charset=utf-8")
	req.Header.Add("X-HW-SIGN", "******")
	req.Header.Add("X-HW-ID", "come.***.bialert")
	req.Header.Add("X-HW-DATE", "20180518T151936Z")

	resp, _ := client.Do(req)
	defer resp.Body.Close()

	body, _ := ioutil.ReadAll(resp.Body)
	fmt.Println(string(body))
}

func main() {
	host, _ := os.Hostname()
	var arg2, arg3 string

	flag.StringVar(&arg2, "tel", "13688888888", "phone number list(comma separated values)")
	flag.StringVar(&arg3, "msg", "alert from "+host, "alert content")

	partten := `^([1][3,4,5,7,8][0-9]{9}\,){0,}[1][3,4,5,7,8][0-9]{9}$`
	match, _ := regexp.MatchString(partten, arg2)

	if !match {
		fmt.Println("wrong phone number list.")
		os.Exit(1)
	}

	p := params{"com.***.bialert", arg2, arg3}
	data, _ := json.Marshal(p)

	httpDo(data)

	// fmt.Println(p)
	// fmt.Println(string(data))
}
