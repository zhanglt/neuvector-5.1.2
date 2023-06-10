#!/bin/bash

check_c() {
  logit ""
  local id="99"
  local desc="社区贡献的支票"
  checkHeader="$id - $desc"
  info "$checkHeader"
  startsectionjson "$id" "$desc"
}

check_c_1() {
  local id="C.1"
  local desc="这是自动检查的示例检查"
  local remediation="这是自动检查的补救措施示例"
  local remediationImpact="这是自动检查的修复影响示例"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if docker info --format='{{ .Architecture }}' | grep 'x86_64' 2>/dev/null 1>&2; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  if docker info --format='{{ .Architecture }}' | grep 'aarch64' 2>/dev/null 1>&2; then
    info -c "$check"
    logcheckresult "INFO"
    return
  fi
  warn -s "$check"
  logcheckresult "WARN"
}

check_c_1_1() {
  local id="C.1.1"
  local desc="这是手动检查的示例检查"
  local remediation="这是手动检查的补救措施示例"
  local remediationImpact="这是手动检查的修复影响示例"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if docker info --format='{{ .Architecture }}' | grep 'x86_64' 2>/dev/null 1>&2; then
    pass -c "$check"
    logcheckresult "PASS"
    return
  fi
  if docker info --format='{{ .Architecture }}' | grep 'aarch64' 2>/dev/null 1>&2; then
    info -c "$check"
    logcheckresult "INFO"
    return
  fi
  warn -c "$check"
  logcheckresult "WARN"
}

check_c_2() {
  docker_version=$(docker version | grep -i -A2 '^server' | grep ' Version:' \
    | awk '{print $NF; exit}' | tr -d '[:alpha:]-,.' | cut -c 1-4)

  local id="C.2"
  local desc="确保禁用对遗留注册表 (v1) 的操作"
  local remediation="使用 --disable-legacy-registry=false 标志启动 docker 守护进程。从 Docker 17.12 开始，删除了对 V1 注册表的支持，并且不能再使用 --disable-legacy-registry 标志。"
  local remediationImpact="防止 docker 守护进程对 v1 注册表进行拉取、推送和登录操作。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if [ "$docker_version" -lt 1712 ]; then
    if get_docker_configuration_file_args 'disable-legacy-registry' | grep 'true' >/dev/null 2>&1; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    if get_docker_effective_command_line_args '--disable-legacy-registry' | grep "disable-legacy-registry" >/dev/null 2>&1; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  local desc="$desc（已弃用）"
  local check="$id - $desc"
  info -c "$check"
  logcheckresult "INFO"
}

check_c_5_3_1() {
  local id="C.5.3.1"
  local desc="确保禁用 CAP_DAC_READ_SEARCH Linux 内核功能（自动）"
  local remediation="PoC请参考https://github.com/cdk-team/CDK/wiki/Exploit:-cap-dac-read-search。"
  local remediationImpact=""
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  caps_containers=""
  for c in $containers; do
    container_caps=$(docker inspect --format 'CapAdd={{ .HostConfig.CapAdd }}' "$c")
    caps=$(echo "$container_caps" | tr "[:lower:]" "[:upper:]" | \
      sed 's/CAPADD/CapAdd/')
    if echo "$caps" | grep -q "DAC_READ_SEARCH"; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "     * CAP_DAC_READ_SEARCH added to $c"
        caps_containers="$caps_containers $c"
        fail=1
        continue
      fi
      warn "     * CAP_DAC_READ_SEARCH added to $c"
      caps_containers="$caps_containers $c"
    fi
  done
  # We went through all the containers and found none with extra capabilities
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "CAP_DAC_READ_SEARCH capability added for containers" "$caps_containers"
}

check_c_5_3_2() {
  local id="C.5.3.2"
  local desc="确保禁用 CAP_SYS_MODULE Linux 内核功能（自动）"
  local remediation="PoC请参考https://xcellerator.github.io/posts/docker_escape/。"
  local remediationImpact=""
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  caps_containers=""
  for c in $containers; do
    container_caps=$(docker inspect --format 'CapAdd={{ .HostConfig.CapAdd }}' "$c")
    caps=$(echo "$container_caps" | tr "[:lower:]" "[:upper:]" | \
      sed 's/CAPADD/CapAdd/')
    if echo "$caps" | grep -q "SYS_MODULE"; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "     * CAP_SYS_MODULE added to $c"
        caps_containers="$caps_containers $c"
        fail=1
        continue
      fi
      warn "     * CAP_SYS_MODULE added to $c"
      caps_containers="$caps_containers $c"
    fi
  done
  # We went through all the containers and found none with extra capabilities
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "CAP_SYS_MODULE capability added for containers" "$caps_containers"
}

check_c_5_3_3() {
  local id="C.5.3.3"
  local desc="确保禁用 CAP_SYS_ADMIN Linux 内核功能（自动）"
  local remediation="PoC请参考https://blog.trailofbits.com/2019/07/19/understanding-docker-container-escapes/。"
  local remediationImpact=""
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  caps_containers=""
  for c in $containers; do
    container_caps=$(docker inspect --format 'CapAdd={{ .HostConfig.CapAdd }}' "$c")
    caps=$(echo "$container_caps" | tr "[:lower:]" "[:upper:]" | \
      sed 's/CAPADD/CapAdd/')
    if echo "$caps" | grep -q "SYS_ADMIN"; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "     * CAP_SYS_ADMIN added to $c"
        caps_containers="$caps_containers $c"
        fail=1
        continue
      fi
      warn "     * CAP_SYS_ADMIN added to $c"
      caps_containers="$caps_containers $c"
    fi
  done
  # We went through all the containers and found none with extra capabilities
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "CAP_SYS_ADMIN capability added for containers" "$caps_containers"
}

check_c_5_3_4() {
  local id="C.5.3.4"
  local desc="确保禁用 CAP_SYS_PTRACE Linux 内核功能（自动）"
  local remediation="请参考 https://0xn3va.gitbook.io/cheat-sheets/container/escaping/excessive-capabilities#cap_sys_ptrace"
  local remediationImpact=""
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  caps_containers=""
  for c in $containers; do
    container_caps=$(docker inspect --format 'CapAdd={{ .HostConfig.CapAdd }}' "$c")
    caps=$(echo "$container_caps" | tr "[:lower:]" "[:upper:]" | \
      sed 's/CAPADD/CapAdd/')
    if echo "$caps" | grep -q "SYS_PTRACE"; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "     * CAP_SYS_PTRACE added to $c"
        caps_containers="$caps_containers $c"
        fail=1
        continue
      fi
      warn "     * CAP_SYS_PTRACE added to $c"
      caps_containers="$caps_containers $c"
    fi
  done
  # We went through all the containers and found none with extra capabilities
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "CAP_SYS_PTRACE capability added for containers" "$caps_containers"
}

check_c_end() {
  endsectionjson
}
