package scan

import (
	"io/ioutil"
	"strings"

	"os"
	"path/filepath"
	"sync"

	"github.com/neuvector/neuvector/share/utils"
	log "github.com/sirupsen/logrus"
)

var exclDirs utils.Set = utils.NewSet("bin", "boot", "dev", "proc", "run", "sys", "tmp")
var rootPath_host string = "/host/proc/1/root/"
var rootLen_host int = len(rootPath_host)

//-------------
var waitGroup sync.WaitGroup
var ch = make(chan struct{}, 255)
var m sync.Map
var fileCount int

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
func walkDir(path string) error {
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
			inpath := path[rootLen_host:]
			tokens := strings.Split(inpath, "/")
			if len(tokens) > 0 && exclDirs.Contains(tokens[0]) {
				return filepath.SkipDir
			}
			if utils.IsMountPoint(path) {
				return filepath.SkipDir
			}
			waitGroup.Add(1)
			go walkDir(filepath.Join(path, e.Name()))
		} else {

			apps := NewScanApps(true)
			apps.extractAppPkg(e.Name(), entries.path+"/"+e.Name())
			for k, v := range apps.pkgs {
				m.Store(k, v)
			}

		}
	}
	return nil
}

func GetHostAppPkgs(path string) ([]byte, error) {
	//t := time.Now()
	appsPkg := NewScanApps(true)
	waitGroup.Add(1)
	go walkDir(path)
	waitGroup.Wait()
	m.Range(func(k, v interface{}) bool {
		appsPkg.pkgs[k.(string)] = v.([]AppPackage)
		return true
	})
	//log.Info("花费的时间为------------ "+time.Since(t).String())
	return appsPkg.marshal(), nil
}
