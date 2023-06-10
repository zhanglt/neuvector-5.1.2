#!/bin/bash

check_1() {
  logit ""
  local id="1"
  local desc="主机配置"
  checkHeader="$id - $desc"
  info "$checkHeader"
  startsectionjson "$id" "$desc"
}

check_1_1() {
  local id="1.1"
  local desc="Linux 主机特定配置"
  local check="$id - $desc"
  info "$check"
}

check_1_1_1() {
  local id="1.1.1"
  local desc="确保已为容器创建单独的分区（自动）"
  local remediation="对于新安装，您应该为 /var/lib/docker 安装点创建一个单独的分区。对于已经安装的系统，您应该使用 Linux 中的逻辑卷管理器 (LVM) 创建一个新分区。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  docker_root_dir=$(docker info -f '{{ .DockerRootDir }}')
  if docker info | grep -q userns ; then
    docker_root_dir=$(readlink -f "$docker_root_dir/..")
  fi

  if mountpoint -q -- "$docker_root_dir" >/dev/null 2>&1; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  warn -s "$check"
  logcheckresult "WARN"
}

check_1_1_2() {
  local id="1.1.2"
  local desc="确保只允许受信任的用户控制 Docker 守护进程（自动）"
  local remediation="您应该使用命令 sudo gpasswd -d <your-user> docker 从 docker 组中删除任何不受信任的用户，或者使用命令 sudo usermod -aG docker <your-user> 将受信任的用户添加到 docker 组。您不应创建从主机到容器卷的敏感目录映射。"
  local remediationImpact="只有信任用户才能像普通用户一样构建和执行容器。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  docker_users=$(grep 'docker' /etc/group)
  if command -v getent >/dev/null 2>&1; then
    docker_users=$(getent group docker)
  fi
  docker_users=$(printf "%s" "$docker_users" | awk -F: '{print $4}')

  local doubtfulusers=""
  if [ -n "$dockertrustusers" ]; then
    for u in $(printf "%s" "$docker_users" | sed "s/,/ /g"); do
      if ! printf "%s" "$dockertrustusers" | grep -q "$u" ; then
        doubtfulusers="$u"
        if [ -n "${doubtfulusers}" ]; then
          doubtfulusers="${doubtfulusers},$u"
        fi
      fi
    done
  else
    info -c "$check"
    info "      * Users: $docker_users"
    logcheckresult "INFO" "doubtfulusers" "$docker_users"
  fi

  if [ -n "${doubtfulusers}" ]; then
    warn -s "$check"
    warn "      * Doubtful users: $doubtfulusers"
    logcheckresult "WARN" "doubtfulusers" "$doubtfulusers"
  fi

  if [ -z "${doubtfulusers}" ] && [ -n "${dockertrustusers}" ]; then
    pass -s "$check"
    logcheckresult "PASS"
  fi
}

check_1_1_3() {
  local id="1.1.3"
  local desc="确保为 Docker 守护程序配置审计（自动）"
  local remediation="安装 auditd。将 -w /usr/bin/dockerd -k docker 添加到 /etc/audit/rules.d/audit.rules 文件。然后使用命令 service auditd restart 重新启动审计守护进程。"
  local remediationImpact="审核可以生成大型日志文件。因此，您需要确保定期轮换和存档它们。为审计日志创建一个单独的分区，以避免填满其他关键分区。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/usr/bin/dockerd"
  if command -v auditctl >/dev/null 2>&1; then
    if auditctl -l | grep "$file" >/dev/null 2>&1; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  warn -s "$check"
  logcheckresult "WARN"
}

check_1_1_4() {
  local id="1.1.4"
  local desc="确保为 Docker 文件和目录配置审计 -/run/containerd（自动）"
  local remediation="安装 auditd。添加 -a exit,always -F path=/run/containerd -F perm=war -k docker 到 /etc/audit/rules.d/audit.rules 文件。然后使用命令 service auditd restart 重新启动审计守护进程。"
  local remediationImpact="审核可以生成大型日志文件。因此，您需要确保定期轮换和存档它们。为审计日志创建一个单独的分区，以避免填满其他关键分区。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/run/containerd"
  if command -v auditctl >/dev/null 2>&1; then
    if auditctl -l | grep "$file" >/dev/null 2>&1; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  warn -s "$check"
  logcheckresult "WARN"
}

check_1_1_5() {
  local id="1.1.5"
  local desc="确保为 Docker 文件和目录配置审计 - /var/lib/docker（自动）"
  local remediation="安装 auditd。将 -w /var/lib/docker -k docker 添加到 /etc/audit/rules.d/audit.rules 文件。然后使用命令 service auditd restart 重新启动审计守护进程。"
  local remediationImpact="审核可以生成大型日志文件。因此，您需要确保定期轮换和存档它们。为审计日志创建一个单独的分区，以避免填满其他关键分区。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  directory="/var/lib/docker"
  if [ -d "$directory" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $directory >/dev/null 2>&1; then
        pass -s "$check"
        logcheckresult "PASS"
        return
      fi
      warn -s "$check"
      logcheckresult "WARN"
      return
    fi
    if grep -s "$directory" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  info -c "$check"
  info "       * Directory not found"
  logcheckresult "INFO" "Directory not found"
}

check_1_1_6() {
  local id="1.1.6"
  local desc="确保为 Docker 文件和目录配置审计 - /etc/docker（自动）"
  local remediation="安装 auditd。将 -w /etc/docker -k docker 添加到 /etc/audit/rules.d/audit.rules 文件。然后使用命令 service auditd restart 重新启动审计守护进程。"
  local remediationImpact="审核可以生成大型日志文件。因此，您需要确保定期轮换和存档它们。为审计日志创建一个单独的分区，以避免填满其他关键分区。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  directory="/etc/docker"
  if [ -d "$directory" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $directory >/dev/null 2>&1; then
        pass -s "$check"
        logcheckresult "PASS"
        return
      fi
      warn -s "$check"
      logcheckresult "WARN"
      return
    fi
    if grep -s "$directory" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  info -c "$check"
  info "       * Directory not found"
  logcheckresult "INFO" "Directory not found"
}

check_1_1_7() {
  local id="1.1.7"
  local desc="确保为 Docker 文件和目录配置审计 - docker.service（自动）"
  local remediation="安装 auditd。添加 -w $(get_service_file docker.service) -k docker 到 /etc/audit/rules.d/audit.rules 文件。然后使用命令 service auditd restart 重新启动审计守护进程。"
  local remediationImpact="审核可以生成大型日志文件。因此，您需要确保定期轮换和存档它们。为审计日志创建一个单独的分区，以避免填满其他关键分区。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="$(get_service_file docker.service)"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep "$file" >/dev/null 2>&1; then
        pass -s "$check"
        logcheckresult "PASS"
        return
      fi
      warn -s "$check"
      logcheckresult "WARN"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  info -c "$check"
  info "       * File not found"
  logcheckresult "INFO" "File not found"
}

check_1_1_8() {
  local id="1.1.8"
  local desc="确保为 Docker 文件和目录配置审计 - containerd.sock（自动）"
  local remediation="安装 auditd。添加 -w $(get_service_file containerd.socket) -k docker 到 /etc/audit/rules.d/audit.rules 文件。然后使用命令 service auditd restart 重新启动审计守护进程。"
  local remediationImpact="审核可以生成大型日志文件。因此，您需要确保定期轮换和存档它们。为审计日志创建一个单独的分区，以避免填满其他关键分区。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="$(get_service_file containerd.socket)"
  if [ -e "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep "$file" >/dev/null 2>&1; then
        pass -s "$check"
        logcheckresult "PASS"
        return
      fi
      warn -s "$check"
      logcheckresult "WARN"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  info -c "$check"
  info "       * File not found"
  logcheckresult "INFO" "File not found"
}
check_1_1_9() {
  local id="1.1.9"
  local desc="确保为 Docker 文件和目录配置审计 - docker.socket（自动）"
  local remediation="安装 auditd。添加 -w $(get_service_file docker.socket) -k docker 到 /etc/audit/rules.d/audit.rules 文件。然后使用命令 service auditd restart 重新启动审计守护进程。"
  local remediationImpact="审核可以生成大型日志文件。因此，您需要确保定期轮换和存档它们。为审计日志创建一个单独的分区，以避免填满其他关键分区。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="$(get_service_file docker.socket)"
  if [ -e "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep "$file" >/dev/null 2>&1; then
        pass -s "$check"
        logcheckresult "PASS"
        return
      fi
      warn -s "$check"
      logcheckresult "WARN"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  info -c "$check"
  info "       * File not found"
  logcheckresult "INFO" "File not found"
}

check_1_1_10() {
  local id="1.1.10"
  local desc="确保为 Docker 文件和目录配置审计 - /etc/default/docker（自动）"
  local remediation="安装 auditd。将 -w /etc/default/docker -k docker 添加到 /etc/audit/rules.d/audit.rules 文件。然后使用命令 service auditd restart 重新启动审计守护进程。"
  local remediationImpact="审核可以生成大型日志文件。因此，您需要确保定期轮换和存档它们。为审计日志创建一个单独的分区，以避免填满其他关键分区。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/etc/default/docker"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $file >/dev/null 2>&1; then
        pass -s "$check"
        logcheckresult "PASS"
        return
      fi
      warn -s "$check"
      logcheckresult "WARN"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  info -c "$check"
  info "       * File not found"
  logcheckresult "INFO" "File not found"
}

check_1_1_11() {
  local id="1.1.11"
  local desc="确保为 Dockerfiles 和目录配置审计 - /etc/docker/daemon.json（自动）"
  local remediation="安装 auditd。添加 -w /etc/docker/daemon.json -k docker 到 /etc/audit/rules.d/audit.rules 文件。然后使用命令 service auditd restart 重新启动审计守护进程。"
  local remediationImpact="审核可以生成大型日志文件。因此，您需要确保定期轮换和存档它们。为审计日志创建一个单独的分区，以避免填满其他关键分区。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/etc/docker/daemon.json"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $file >/dev/null 2>&1; then
        pass -s "$check"
        logcheckresult "PASS"
        return
      fi
      warn -s "$check"
      logcheckresult "WARN"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  info -c "$check"
  info "       * File not found"
  logcheckresult "INFO" "File not found"
}

check_1_1_12() {
  local id="1.1.12"
  local desc="确保为 Dockerfiles 和目录配置审计 - /etc/containerd/config.toml（自动）"
  local remediation="安装 auditd。将 -w /etc/containerd/config.toml -k docker 添加到 /etc/audit/rules.d/audit.rules 文件。然后使用命令 service auditd restart 重新启动审计守护进程。"
  local remediationImpact="审核可以生成大型日志文件。因此，您需要确保定期轮换和存档它们。为审计日志创建一个单独的分区，以避免填满其他关键分区。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/etc/containerd/config.toml"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $file >/dev/null 2>&1; then
        pass -s "$check"
        logcheckresult "PASS"
        return
      fi
      warn -s "$check"
      logcheckresult "WARN"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  info -c "$check"
  info "       * File not found"
  logcheckresult "INFO" "File not found"
}

check_1_1_13() {
  local id="1.1.13"
  local desc="确保为 Docker 文件和目录配置审计 - /etc/sysconfig/docker（自动）"
  local remediation="安装 auditd。将 -w /etc/sysconfig/docker -k docker 添加到 /etc/audit/rules.d/audit.rules 文件。然后使用命令 service auditd restart 重新启动审计守护进程。"
  local remediationImpact="审核可以生成大型日志文件。因此，您需要确保定期轮换和存档它们。为审计日志创建一个单独的分区，以避免填满其他关键分区。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/etc/sysconfig/docker"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $file >/dev/null 2>&1; then
        pass -s "$check"
        logcheckresult "PASS"
        return
      fi
      warn -s "$check"
      logcheckresult "WARN"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  info -c "$check"
  info "       * File not found"
  logcheckresult "INFO" "File not found"
}

check_1_1_14() {
  local id="1.1.14"
  local desc="确保为 Docker 文件和目录配置审计 - /usr/bin/containerd（自动）"
  local remediation="安装 auditd。将 -w /usr/bin/containerd -k docker 添加到 /etc/audit/rules.d/audit.rules 文件。然后使用命令 service auditd restart 重新启动审计守护进程。"
  local remediationImpact="审核可以生成大型日志文件。因此，您需要确保定期轮换和存档它们。为审计日志创建一个单独的分区，以避免填满其他关键分区。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/usr/bin/containerd"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $file >/dev/null 2>&1; then
        pass -s "$check"
        logcheckresult "PASS"
        return
      fi
      warn -s "$check"
      logcheckresult "WARN"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  info -c "$check"
  info "        * File not found"
  logcheckresult "INFO" "File not found"
}

check_1_1_15() {
  local id="1.1.15"
  local desc="确保为 Docker 文件和目录配置审计 - /usr/bin/containerd-shim（自动）"
  local remediation="安装 auditd。将 -w /usr/bin/containerd-shim -k docker 添加到 /etc/audit/rules.d/audit.rules 文件。然后使用命令 service auditd restart 重新启动审计守护进程。"
  local remediationImpact="审核可以生成大型日志文件。因此，您需要确保定期轮换和存档它们。为审计日志创建一个单独的分区，以避免填满其他关键分区。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/usr/bin/containerd-shim"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $file >/dev/null 2>&1; then
        pass -s "$check"
        logcheckresult "PASS"
        return
      fi
      warn -s "$check"
      logcheckresult "WARN"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  info -c "$check"
  info "        * File not found"
  logcheckresult "INFO" "File not found"
}

check_1_1_16() {
  local id="1.1.16"
  local desc="确保为 Docker 文件和目录配置审计 - /usr/bin/containerd-shim-runc-v1（自动）"
  local remediation="安装 auditd。将 -w /usr/bin/containerd-shim-runc-v1 -k docker 添加到 /etc/audit/rules.d/audit.rules 文件。然后使用命令 service auditd restart 重新启动审计守护进程。"
  local remediationImpact="审核可以生成大型日志文件。因此，您需要确保定期轮换和存档它们。为审计日志创建一个单独的分区，以避免填满其他关键分区。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/usr/bin/containerd-shim-runc-v1"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $file >/dev/null 2>&1; then
        pass -s "$check"
        logcheckresult "PASS"
        return
      fi
      warn -s "$check"
      logcheckresult "WARN"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  info -c "$check"
  info "        * File not found"
  logcheckresult "INFO" "File not found"
}

check_1_1_17() {
  local id="1.1.17"
  local desc="确保为 Docker 文件和目录配置审计 - /usr/bin/containerd-shim-runc-v2（自动）"
  local remediation="安装 auditd。将 -w /usr/bin/containerd-shim-runc-v2 -k docker 添加到 /etc/audit/rules.d/audit.rules 文件。然后使用命令 service auditd restart 重新启动审计守护进程。"
  local remediationImpact="审核可以生成大型日志文件。因此，您需要确保定期轮换和存档它们。为审计日志创建一个单独的分区，以避免填满其他关键分区。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/usr/bin/containerd-shim-runc-v2"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $file >/dev/null 2>&1; then
        pass -s "$check"
        logcheckresult "PASS"
        return
      fi
      warn -s "$check"
      logcheckresult "WARN"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  info -c "$check"
  info "        * File not found"
  logcheckresult "INFO" "File not found"
}

check_1_1_18() {
  local id="1.1.18"
  local desc="确保为 Docker 文件和目录配置审计 - /usr/bin/runc（自动）"
  local remediation="安装 auditd。将 -w /usr/bin/runc -k docker 添加到 /etc/audit/rules.d/audit.rules 文件。然后使用命令 service auditd restart 重新启动审计守护进程。"
  local remediationImpact="审核可以生成大型日志文件。因此，您需要确保定期轮换和存档它们。为审计日志创建一个单独的分区，以避免填满其他关键分区。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/usr/bin/runc"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $file >/dev/null 2>&1; then
        pass -s "$check"
        logcheckresult "PASS"
        return
      fi
      warn -s "$check"
      logcheckresult "WARN"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  info -c "$check"
  info "        * File not found"
  logcheckresult "INFO" "File not found"
}

check_1_2() {
  local id="1.2"
  local desc="一般配置"
  local check="$id - $desc"
  info "$check"
}

check_1_2_1() {
  local id="1.2.1"
  local desc="确保容器主机已加固（手动）"
  local remediation="您可以为您的容器主机考虑各种安全基准。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "INFO"
}

check_1_2_2() {
  local id="1.2.2"
  local desc="确保 Docker 的版本是最新的（手动）"
  local remediation="您应该监控 Docker 版本并确保您的软件按要求更新。"
  local remediationImpact="您应该执行有关 Docker 版本更新的风险评估，并查看它们如何影响您的操作。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  docker_version=$(docker version | grep -i -A2 '^server' | grep ' Version:' \
    | awk '{print $NF; exit}' | tr -d '[:alpha:]-,')
  docker_current_version="$(date +%y.%m.0 -d @$(( $(date +%s) - 2592000)))"
  do_version_check "$docker_current_version" "$docker_version"
  if [ $? -eq 11 ]; then
    pass -c "$check"
    info "       * Using $docker_version, verify is it up to date as deemed necessary"
    logcheckresult "INFO" "Using $docker_version"
    return
  fi
  pass -c "$check"
  info "       * Using $docker_version which is current"
  info "       * Check with your operating system vendor for support and security maintenance for Docker"
  logcheckresult "PASS" "Using $docker_version"
}

check_1_end() {
  endsectionjson
}
