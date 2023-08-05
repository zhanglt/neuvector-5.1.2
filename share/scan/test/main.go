package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"math"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/neuvector/neuvector/share/utils"
)

const (
	//goTest目录
	GO_TEST_DIR_PATH = "/"
)

var waitGroup sync.WaitGroup

//var wg sync.WaitGroup
var ch = make(chan struct{}, 100)

type fileInfo struct {
	of   []os.FileInfo
	path string
}

func dirents(path string) (fileInfo, bool) {
	f := fileInfo{}
	entries, err := ioutil.ReadDir(path)
	if err != nil {
		log.Fatal(err)
		return f, false
	}
	f = fileInfo{entries, path}
	return f, true
}

// 递归计算目录下所有文件
func walkDir(path string, fileSize chan<- string) error {
	exclDirs := utils.NewSet("bin", "boot", "dev", "proc", "run", "sys", "tmp", "lib")
	rootPath := path
	rootLen := len(rootPath)
	defer waitGroup.Done()
	//	fmt.Printf("\rwalk ... %s\n", path)
	ch <- struct{}{} //限制并发量
	entries, ok := dirents(path)
	<-ch
	if !ok {
		log.Fatal("can not find this dir path!!")
		return nil
	}
	for _, e := range entries.of {
		if e.IsDir() {
			inpath := path[rootLen:]
			tokens := strings.Split(inpath, "/")
			if len(tokens) > 0 && exclDirs.Contains(tokens[0]) {
				return filepath.SkipDir
			}
			if utils.IsMountPoint(path) {
				return filepath.SkipDir
			}
			waitGroup.Add(1)
			go walkDir(filepath.Join(path, e.Name()), fileSize)
		} else {
			//fileSize <- e.Size()
			//fmt.Println("----------------:", e.Name())
			//wg.Add(1)
			fileSize <- entries.path + "/" + e.Name()

		}
	}
	return nil
}

func CutStringSlice(slice []string, shareNums int) *[][]string {
	sliceLen := len(slice)
	if sliceLen == 0 {
		panic("slice is nil")
	}
	totalShareNums := math.Ceil(float64(sliceLen) / float64(shareNums))
	resSlice := make([][]string, 0, int(totalShareNums))

	for i := 0; i < sliceLen; i += shareNums {
		endIndex := i + shareNums
		if endIndex > sliceLen {
			endIndex = sliceLen
		}
		resSlice = append(resSlice, slice[i:endIndex])
	}

	return &resSlice
}

func main() {
	//var mu sync.RWMutex
	//文件大小chennel
	pkgs := make(map[string]string)
	f := []string{}

	fileList := make(chan string)
	var fileCount int
	waitGroup.Add(1)

	go walkDir(GO_TEST_DIR_PATH, fileList)
	//go scan.WalkDir_host(GO_TEST_DIR_PATH, fileList, wg)
	go func() {
		defer close(fileList)
		waitGroup.Wait()
		//	wg1.Wait()

	}()

	t := time.Now()

	for file := range fileList {
		//	fmt.Println(size)
		fileCount++
		//time.Sleep(1 * time.Second)
		//go func(f string) {
		//fmt.Println(f)
		//}(file)
		filename := filepath.Base(file)
		if _, ok := pkgs[filename]; !ok {

			pkgs[filename] = file
			f = append(f, file)
		}

		//	file = append(file, f)

	}
	/*
		s := CutStringSlice(f, 10)
		//var m = make(map[string][]scan.AppPackage)
		for _, x := range *s {
			wg1.Add(1)
			go func(z []string) {
				for _, y := range z {
					fmt.Println(y)
				}

				wg1.Done()
			}(x)
		}

		/*
			go func() {
				for {
					mu.RLock()
					val, ok := <-fileList
					mu.RUnlock()
					if !ok {
						break
					}

					fmt.Println("Received value:", val)
				}
			}()

				my := []string{"a", "b", "c", "d", "e", "f"}
				s := CutStringSlice(my, 2)
				for _, x := range *s {
					wg.Add(1)
					go func(z []string) {
						for _, y := range z {
							fmt.Println(y)
						}
						wg.Done()
					}(x)
				}
	*/
	//time.Sleep(10 * time.Second)
	//time.Sleep(1 * time.Second)

	fmt.Println("花费的时间为 " + time.Since(t).String())
	fmt.Printf("文件总数为 %d\n,%d\n,%d\n", fileCount, len(pkgs), len(f))

}
