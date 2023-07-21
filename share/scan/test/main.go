package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/neuvector/neuvector/share/utils"
)

func main() {
	t1 := time.Now() // get current time
	filepath.Walk("/opt", func(path string, info os.FileInfo, err error) error {
		rootLen := len(path)
		//bTimeoutFlag := false
		go func() {
			if info.IsDir() {
				//apps := scan.NewScanApps(true)
				//fmt.Println("0000000000000")
				filepath.Walk(path, func(path string, in os.FileInfo, err error) error {
					fmt.Println(path)

					if info.IsDir() {
						inpath := path[rootLen:]
						tokens := strings.Split(inpath, "/")
						if len(tokens) > 0 {
							return filepath.SkipDir
						}
						if utils.IsMountPoint(path) {
							return filepath.SkipDir
						}
					} else {
						inpath := path[rootLen:]
						fmt.Println(inpath, path)
						//apps.extractAppPkg(inpath, path)
					}
					return nil
				})
			} else if info.Mode().IsRegular() && info.Size() > 0 {
				inpath := path[rootLen:]
				fmt.Println("----------------------:", inpath, path)
				//apps.extractAppPkg(inpath, path)
			}

		}()
		return nil
	})
	fmt.Println("App elapsed: ", time.Since(t1))
}

func path(info os.FileInfo, path string, rootLen int) {

	if info.IsDir() {
		//apps := scan.NewScanApps(true)
		//fmt.Println("0000000000000")
		filepath.Walk(path, func(path string, in os.FileInfo, err error) error {
			fmt.Println(path)

			if info.IsDir() {
				inpath := path[rootLen:]
				tokens := strings.Split(inpath, "/")
				if len(tokens) > 0 {
					return filepath.SkipDir
				}
				if utils.IsMountPoint(path) {
					return filepath.SkipDir
				}
			} else {
				fmt.Println("11111111111111111111")
				inpath := path[rootLen:]
				fmt.Println(inpath, path)
				//apps.extractAppPkg(inpath, path)
			}
			return nil
		})
	} else if info.Mode().IsRegular() && info.Size() > 0 {
		inpath := path[rootLen:]
		fmt.Println("----------------------:", inpath, path)
		//apps.extractAppPkg(inpath, path)
	}

}
