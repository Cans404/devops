// created by Cans, 20180509

package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"path/filepath"
)

// 返回文件或目录（递归统计）大小，单位 byte
func getSize(file string) int64 {
	f, _ := os.Stat(file)
	var size_b int64

	if f.IsDir() == false {
		size_b = f.Size()
	} else {
		filepath.Walk(file, func(path string, info os.FileInfo, err error) error {
			size_b += info.Size()
			return nil
			})
	}

	return size_b
}

// 带父目录返回目录下的文件列表
func getFiles(path string) []string {
	var files []string
	cmd := exec.Command("ls", path)
	out, _ := cmd.CombinedOutput()
	tmp := strings.Split(string(out), "\n")

	for _, file := range tmp {
		files = append(files, path + "/" + file)
	}

	return files
}

func locator(dir string, m map[string]int64) string {
	flg := "N"
	for _, file := range getFiles(dir) {
		f, _ := os.Stat(file)
		pct := getSize(file) * 100 / total

		if pct > topPct {
			flg = "Y"
			if f.IsDir() == false {
				m[file] = pct
			} else {
				if locator(file, m) == "N" {
					m[file] = pct
				}
			}
		}
	}

	return flg
}

var dir = "../"
var total = getSize(dir)
var topPct = int64(10)

func main() {
	top := make(map[string]int64)

	locator(dir, top)

	for k, v := range top {
		fmt.Printf("%s: %10s\n", k, v)
	}
}
