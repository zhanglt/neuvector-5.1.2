#!/bin/bash

check_6() {
  logit ""
  local id="6"
  local desc="Docker 安全操作"
  checkHeader="$id - $desc"
  info "$checkHeader"
  startsectionjson "$id" "$desc"
}

check_6_1() {
  local id="6.1"
  local desc="确保避免图像蔓延（手动）"
  local remediation="您应该只保留您实际需要的图像，并建立一个工作流程以从主机中删除旧的或陈旧的图像。此外，您应该使用 pull-by-digest 等功能从注册表中获取特定图像。"
  local remediationImpact="docker system prune -a 删除所有退出的容器以及所有未被运行容器引用的图像和卷​​，包括 UCP 和 DTR。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  images=$(docker images -q | sort -u | wc -l | awk '{print $1}')
  active_images=0

  for c in $(docker inspect --format "{{.Image}}" "$(docker ps -qa)" 2>/dev/null); do
    if docker images --no-trunc -a | grep "$c" > /dev/null ; then
      active_images=$(( active_images += 1 ))
    fi
  done

  info -c "$check"
  info "     * There are currently: $images images"

  if [ "$active_images" -lt "$((images / 2))" ]; then
    info "     * Only $active_images out of $images are in use"
  fi
  logcheckresult "INFO" "$active_images active/$images in use"
}

check_6_2() {
  local id="6.2"
  local desc="确保避免容器蔓延（手动）"
  local remediation="您应该定期检查每台主机上的容器清单，并使用以下命令清理未使用的容器：docker container prune"
  local remediationImpact="您应该保留正在使用的容器，并删除不再需要的容器。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  total_containers=$(docker info 2>/dev/null | grep "Containers" | awk '{print $2}')
  running_containers=$(docker ps -q | wc -l | awk '{print $1}')
  diff="$((total_containers - running_containers))"
  info -c "$check"
  if [ "$diff" -gt 25 ]; then
    info "     * There are currently a total of $total_containers containers, with only $running_containers of them currently running"
  else
    info "     * There are currently a total of $total_containers containers, with $running_containers of them currently running"
  fi
  logcheckresult "INFO" "$total_containers total/$running_containers running"
}

check_6_end() {
  endsectionjson
}
