/**
*翻译tests目录中的条目
 */
package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"strings"

	translator "github.com/Conight/go-googletrans"
)

func t(text string, t *translator.Translator) string {

	result, err := t.Translate(text, "en", "zh")
	if err != nil {
		panic(err)
	}

	return result.Text

}

func main() {
	//需要翻译的文件列表
	var tmpl []string
	tmpl = append(tmpl, "1_host_configuration.sh")
	tmpl = append(tmpl, "2_docker_daemon_configuration.sh")
	tmpl = append(tmpl, "3_docker_daemon_configuration_files.sh")
	tmpl = append(tmpl, "4_container_images.sh")
	tmpl = append(tmpl, "5_container_runtime.sh")
	tmpl = append(tmpl, "6_docker_security_operations.sh")
	tmpl = append(tmpl, "7_docker_swarm_configuration.sh")
	tmpl = append(tmpl, "8_docker_enterprise_configuration.sh")
	tmpl = append(tmpl, "99_community_checks.sh")
	c := translator.Config{
		Proxy: "http://127.0.0.1:10809",
	}
	ts := translator.New(c)

	for _, file := range tmpl {

		err := ReadLines("../tests/"+file, "../tests_zh/"+file, ts)
		if err != nil {
			fmt.Printf("%s文件处理错误:%s", file, err)
		}
	}

}

func ReadLines(inFile, outFile string, ts *translator.Translator) error {
	in, err := os.Open(inFile)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.OpenFile(outFile, os.O_WRONLY|os.O_CREATE|os.O_APPEND, 0666)
	if err != nil {
		return err
	}
	defer out.Close()
	write := bufio.NewWriter(out)
	read := bufio.NewReader(in)
	for {
		bytes, _, err := read.ReadLine()
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}
		s := string(bytes)
		tmp := getStr(ts, s, "local desc=", "local remediation=", "local remediationImpact=")
		if tmp != "" {
			s = tmp
		}
		write.WriteString(fmt.Sprintf("%s\n", s))
	}

	err = write.Flush()
	return err
}
func getStr(ts *translator.Translator, str string, substr ...string) string {
	for _, item := range substr {
		if strings.Contains(str, item) {
			return substring(str, item, ts)
		}
	}
	return ""
}
func substring(str, substr string, ts *translator.Translator) string {
	var s string
	l := len(str)
	i := strings.Index(str, substr)
	s = str[i+len(substr)+1 : l-1]
	if s != "" && s != "None." {
		s = t(s, ts)
	}
	s = str[0:i+len(substr)+1] + s + str[l-1:l]
	return s
}
