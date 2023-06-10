#!/bin/bash

check_3() {
  logit ""
  local id="3"
  local desc="Docker 守护进程配置文件"
  checkHeader="$id - $desc"
  info "$checkHeader"
  startsectionjson "$id" "$desc"
}

check_3_1() {
  local id="3.1"
  local desc="确保 docker.service 文件所有权设置为 root:root（自动）"
  local remediation="找出文件位置：systemctl show -p FragmentPath docker.service。如果该文件不存在，则此建议不适用。如果该文件确实存在，您应该运行命令 chown root:root <path>，以便将文件的所有权和组所有权设置为 root。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file=$(get_service_file docker.service)
  if [ -f "$file" ]; then
    if [ "$(stat -c %u%g "$file")" -eq 00 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "     * Wrong ownership for $file"
    logcheckresult "WARN" "Wrong ownership for $file"
    return
  fi
  info -c "$check"
  info "     * File not found"
  logcheckresult "INFO" "File not found"
}

check_3_2() {
  local id="3.2"
  local desc="确保正确设置 docker.service 文件权限（自动）"
  local remediation="找出文件位置：systemctl show -p FragmentPath docker.service。如果该文件不存在，则此建议不适用。如果文件存在，执行命令chmod 644 <path>，设置文件权限为644。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file=$(get_service_file docker.service)
  if [ -f "$file" ]; then
    if [ "$(stat -c %a "$file")" -le 644 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "     * Wrong permissions for $file"
    logcheckresult "WARN" "Wrong permissions for $file"
    return
  fi
  info -c "$check"
  info "     * File not found"
  logcheckresult "INFO" "File not found"
}

check_3_3() {
  local id="3.3"
  local desc="确保 docker.socket 文件所有权设置为 root:root（自动）"
  local remediation="找出文件位置：systemctl show -p FragmentPath docker.socket。如果该文件不存在，则此建议不适用。如果该文件存在，则运行命令chown root:root <path> 将文件的所有权和所属组设置为root。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file=$(get_service_file docker.socket)
  if [ -f "$file" ]; then
    if [ "$(stat -c %u%g "$file")" -eq 00 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "     * Wrong ownership for $file"
    logcheckresult "WARN" "Wrong ownership for $file"
    return
  fi
  info -c "$check"
  info "     * File not found"
  logcheckresult "INFO" "File not found"
}

check_3_4() {
  local id="3.4"
  local desc="确保 docker.socket 文件权限设置为 644 或更多限制（自动）"
  local remediation="找出文件位置：systemctl show -p FragmentPath docker.socket。如果该文件不存在，则此建议不适用。如果该文件确实存在，则应运行命令 chmod 644 <path> 将文件权限设置为 644。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file=$(get_service_file docker.socket)
  if [ -f "$file" ]; then
    if [ "$(stat -c %a "$file")" -le 644 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "     * Wrong permissions for $file"
    logcheckresult "WARN" "Wrong permissions for $file"
    return
  fi
  info -c "$check"
  info "     * File not found"
  logcheckresult "INFO" "File not found"
}

check_3_5() {
  local id="3.5"
  local desc="确保 /etc/docker 目录所有权设置为 root:root（自动）"
  local remediation="您应该运行以下命令：chown root:root /etc/docker.这会将目录的所有权和组所有权设置为 root。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  directory="/etc/docker"
  if [ -d "$directory" ]; then
    if [ "$(stat -c %u%g $directory)" -eq 00 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "     * Wrong ownership for $directory"
    logcheckresult "WARN" "Wrong ownership for $directory"
    return
  fi
  info -c "$check"
  info "     * Directory not found"
  logcheckresult "INFO" "Directory not found"
}

check_3_6() {
  local id="3.6"
  local desc="确保 /etc/docker 目录权限设置为 755 或更严格（自动）"
  local remediation="您应该运行以下命令：chmod 755 /etc/docker.这会将目录的权限设置为 755。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  directory="/etc/docker"
  if [ -d "$directory" ]; then
    if [ "$(stat -c %a $directory)" -le 755 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "     * Wrong permissions for $directory"
    logcheckresult "WARN" "Wrong permissions for $directory"
    return
  fi
  info -c "$check"
  info "     * Directory not found"
  logcheckresult "INFO" "Directory not found"
}

check_3_7() {
  local id="3.7"
  local desc="确保注册表证书文件所有权设置为 root:root（自动）"
  local remediation="您应该运行以下命令：chown root:root /etc/docker/certs.d/<registry-name>/*。这会将注册表证书文件的个人所有权和组所有权设置为根。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  directory="/etc/docker/certs.d/"
  if [ -d "$directory" ]; then
    fail=0
    owners=$(find "$directory" -type f -name '*.crt')
    for p in $owners; do
      if [ "$(stat -c %u "$p")" -ne 0 ]; then
        fail=1
      fi
    done
    if [ $fail -eq 1 ]; then
      warn -s "$check"
      warn "     * Wrong ownership for $directory"
      logcheckresult "WARN" "Wrong ownership for $directory"
      return
    fi
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  info -c "$check"
  info "     * Directory not found"
  logcheckresult "INFO" "Directory not found"
}

check_3_8() {
  local id="3.8"
  local desc="确保注册表证书文件权限设置为 444 或更严格（自动）"
  local remediation="您应该运行以下命令：chmod 444 /etc/docker/certs.d/<registry-name>/*。这会将注册表证书文件的权限设置为 444。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  directory="/etc/docker/certs.d/"
  if [ -d "$directory" ]; then
    fail=0
    perms=$(find "$directory" -type f -name '*.crt')
    for p in $perms; do
      if [ "$(stat -c %a "$p")" -gt 444 ]; then
        fail=1
      fi
    done
    if [ $fail -eq 1 ]; then
      warn -s "$check"
      warn "     * Wrong permissions for $directory"
      logcheckresult "WARN" "Wrong permissions for $directory"
      return
    fi
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  info -c "$check"
  info "     * Directory not found"
  logcheckresult "INFO" "Directory not found"
}

check_3_9() {
  local id="3.9"
  local desc="确保 TLS CA 证书文件所有权设置为 root:root（自动）"
  local remediation="您应该运行以下命令：chown root:root <path to TLS CA certificate file>。这会将 TLS CA 证书文件的个人所有权和组所有权设置为根。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  tlscacert=$(get_docker_effective_command_line_args '--tlscacert' | sed -n 's/.*tlscacert=\([^s]\)/\1/p' | sed 's/--/ --/g' | cut -d " " -f 1)
  if [ -n "$(get_docker_configuration_file_args 'tlscacert')" ]; then
    tlscacert=$(get_docker_configuration_file_args 'tlscacert')
  fi
  if [ -f "$tlscacert" ]; then
    if [ "$(stat -c %u%g "$tlscacert")" -eq 00 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "     * Wrong ownership for $tlscacert"
    logcheckresult "WARN" "Wrong ownership for $tlscacert"
    return
  fi
  info -c "$check"
  info "     * No TLS CA certificate found"
  logcheckresult "INFO" "No TLS CA certificate found"
}

check_3_10() {
  local id="3.10"
  local desc="确保 TLS CA 证书文件权限设置为 444 或更严格（自动）"
  local remediation="您应该运行以下命令：chmod 444 <TLS CA 证书文件的路径>。这会将 TLS CA 文件的文件权限设置为 444。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  tlscacert=$(get_docker_effective_command_line_args '--tlscacert' | sed -n 's/.*tlscacert=\([^s]\)/\1/p' | sed 's/--/ --/g' | cut -d " " -f 1)
  if [ -n "$(get_docker_configuration_file_args 'tlscacert')" ]; then
    tlscacert=$(get_docker_configuration_file_args 'tlscacert')
  fi
  if [ -f "$tlscacert" ]; then
    if [ "$(stat -c %a "$tlscacert")" -le 444 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "      * Wrong permissions for $tlscacert"
    logcheckresult "WARN" "Wrong permissions for $tlscacert"
    return
  fi
  info -c "$check"
  info "      * No TLS CA certificate found"
  logcheckresult "INFO" "No TLS CA certificate found"
}

check_3_11() {
  local id="3.11"
  local desc="确保 Docker 服务器证书文件所有权设置为 root:root（自动）"
  local remediation="您应该运行以下命令：chown root:root < Docker 服务器证书文件的路径>。这会将 Docker 服务器证书文件的个人所有权和组所有权设置为 root。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  tlscert=$(get_docker_effective_command_line_args '--tlscert' | sed -n 's/.*tlscert=\([^s]\)/\1/p' | sed 's/--/ --/g' | cut -d " " -f 1)
  if [ -n "$(get_docker_configuration_file_args 'tlscert')" ]; then
    tlscert=$(get_docker_configuration_file_args 'tlscert')
  fi
  if [ -f "$tlscert" ]; then
    if [ "$(stat -c %u%g "$tlscert")" -eq 00 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "      * Wrong ownership for $tlscert"
    logcheckresult "WARN" "Wrong ownership for $tlscert"
    return
  fi
  info -c "$check"
  info "      * No TLS Server certificate found"
  logcheckresult "INFO" "No TLS Server certificate found"
}

check_3_12() {
  local id="3.12"
  local desc="确保 Docker 服务器证书文件权限设置为 444 或更严格（自动）"
  local remediation="您应该运行以下命令：chmod 444 <Docker 服务器证书文件的路径>。这会将 Docker 服务器证书文件的文件权限设置为 444。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  tlscert=$(get_docker_effective_command_line_args '--tlscert' | sed -n 's/.*tlscert=\([^s]\)/\1/p' | sed 's/--/ --/g' | cut -d " " -f 1)
  if [ -n "$(get_docker_configuration_file_args 'tlscert')" ]; then
    tlscert=$(get_docker_configuration_file_args 'tlscert')
  fi
  if [ -f "$tlscert" ]; then
    if [ "$(stat -c %a "$tlscert")" -le 444 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "      * Wrong permissions for $tlscert"
    logcheckresult "WARN" "Wrong permissions for $tlscert"
    return
  fi
  info -c "$check"
  info "      * No TLS Server certificate found"
  logcheckresult "INFO" "No TLS Server certificate found"
}

check_3_13() {
  local id="3.13"
  local desc="确保 Docker 服务器证书密钥文件所有权设置为 root:root（自动）"
  local remediation="您应该运行以下命令：chown root:root < Docker 服务器证书密钥文件的路径>。这会将 Docker 服务器证书密钥文件的个人所有权和组所有权设置为 root。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  tlskey=$(get_docker_effective_command_line_args '--tlskey' | sed -n 's/.*tlskey=\([^s]\)/\1/p' | sed 's/--/ --/g' | cut -d " " -f 1)
  if [ -n "$(get_docker_configuration_file_args 'tlskey')" ]; then
    tlskey=$(get_docker_configuration_file_args 'tlskey')
  fi
  if [ -f "$tlskey" ]; then
    if [ "$(stat -c %u%g "$tlskey")" -eq 00 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "      * Wrong ownership for $tlskey"
    logcheckresult "WARN" "Wrong ownership for $tlskey"
    return
  fi
  info -c "$check"
  info "      * No TLS Key found"
  logcheckresult "INFO" "No TLS Key found"
}

check_3_14() {
  local id="3.14"
  local desc="确保 Docker 服务器证书密钥文件权限设置为 400（自动）"
  local remediation="您应该运行以下命令：chmod 400 <Docker 服务器证书密钥文件的路径>。这会将 Docker 服务器证书密钥文件权限设置为 400。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  tlskey=$(get_docker_effective_command_line_args '--tlskey' | sed -n 's/.*tlskey=\([^s]\)/\1/p' | sed 's/--/ --/g' | cut -d " " -f 1)
  if [ -n "$(get_docker_configuration_file_args 'tlskey')" ]; then
    tlskey=$(get_docker_configuration_file_args 'tlskey')
  fi
  if [ -f "$tlskey" ]; then
    if [ "$(stat -c %a "$tlskey")" -eq 400 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "      * Wrong permissions for $tlskey"
    logcheckresult "WARN" "Wrong permissions for $tlskey"
    return
  fi
  info -c "$check"
  info "      * No TLS Key found"
  logcheckresult "INFO" "No TLS Key found"
}

check_3_15() {
  local id="3.15"
  local desc="确保 Docker 套接字文件所有权设置为 root:docker（自动）"
  local remediation="您应该运行以下命令：chown root:docker /var/run/docker.sock。这会将默认 Docker 套接字文件的所有权设置为 root，并将组所有权设置为 docker。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/var/run/docker.sock"
  if [ -S "$file" ]; then
    if [ "$(stat -c %U:%G $file)" = 'root:docker' ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "      * Wrong ownership for $file"
    logcheckresult "WARN" "Wrong ownership for $file"
    return
  fi
  info -c "$check"
  info "      * File not found"
  logcheckresult "INFO" "File not found"
}

check_3_16() {
  local id="3.16"
  local desc="确保将 Docker 套接字文件权限设置为 660 或更严格（自动）"
  local remediation="您应该运行以下命令：chmod 660 /var/run/docker.sock。这会将 Docker 套接字文件的文件权限设置为 660。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/var/run/docker.sock"
  if [ -S "$file" ]; then
    if [ "$(stat -c %a $file)" -le 660 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "      * Wrong permissions for $file"
    logcheckresult "WARN" "Wrong permissions for $file"
    return
  fi
  info -c "$check"
  info "      * File not found"
  logcheckresult "INFO" "File not found"
}

check_3_17() {
  local id="3.17"
  local desc="确保 daemon.json 文件所有权设置为 root:root（自动）"
  local remediation="您应该运行以下命令：chown root:root /etc/docker/daemon.json。这会将文件的所有权和组所有权设置为 root。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/etc/docker/daemon.json"
  if [ -f "$file" ]; then
    if [ "$(stat -c %U:%G $file)" = 'root:root' ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "      * Wrong ownership for $file"
    logcheckresult "WARN" "Wrong ownership for $file"
    return
  fi
  info -c "$check"
  info "      * File not found"
  logcheckresult "INFO" "File not found"
}

check_3_18() {
  local id="3.18"
  local desc="确保 daemon.json 文件权限设置为 644 或更严格（自动）"
  local remediation="您应该运行以下命令：chmod 644 /etc/docker/daemon.json。这会将此文件的文件权限设置为 644。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/etc/docker/daemon.json"
  if [ -f "$file" ]; then
    if [ "$(stat -c %a $file)" -le 644 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "      * Wrong permissions for $file"
    logcheckresult "WARN" "Wrong permissions for $file"
    return
  fi
  info -c "$check"
  info "      * File not found"
  logcheckresult "INFO" "File not found"
}

check_3_19() {
  local id="3.19"
  local desc="确保 /etc/default/docker 文件所有权设置为 root:root（自动）"
  local remediation="您应该运行以下命令：chown root:root /etc/default/docker。这会将文件的所有权和组所有权设置为 root。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/etc/default/docker"
  if [ -f "$file" ]; then
    if [ "$(stat -c %U:%G $file)" = 'root:root' ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "      * Wrong ownership for $file"
    logcheckresult "WARN" "Wrong ownership for $file"
    return
  fi
  info -c "$check"
  info "      * File not found"
  logcheckresult "INFO" "File not found"
}

check_3_20() {
  local id="3.20"
  local desc="确保 /etc/default/docker 文件权限设置为 644 或更严格（自动）"
  local remediation="您应该运行以下命令：chmod 644 /etc/default/docker。这会将此文件的文件权限设置为 644。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/etc/default/docker"
  if [ -f "$file" ]; then
    if [ "$(stat -c %a $file)" -le 644 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "      * Wrong permissions for $file"
    logcheckresult "WARN" "Wrong permissions for $file"
    return
  fi
  info -c "$check"
  info "      * File not found"
  logcheckresult "INFO" "File not found"
}

check_3_21() {
  local id="3.21"
  local desc="确保 /etc/sysconfig/docker 文件权限设置为 644 或更严格（自动）"
  local remediation="您应该运行以下命令：chmod 644 /etc/sysconfig/docker。这会将此文件的文件权限设置为 644。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/etc/sysconfig/docker"
  if [ -f "$file" ]; then
    if [ "$(stat -c %a $file)" -le 644 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "      * Wrong permissions for $file"
    logcheckresult "WARN" "Wrong permissions for $file"
    return
  fi
  info -c "$check"
  info "      * File not found"
  logcheckresult "INFO" "File not found"
}

check_3_22() {
  local id="3.22"
  local desc="确保 /etc/sysconfig/docker 文件所有权设置为 root:root（自动）"
  local remediation="您应该运行以下命令：chown root:root /etc/sysconfig/docker。这会将文件的所有权和组所有权设置为 root。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/etc/sysconfig/docker"
  if [ -f "$file" ]; then
    if [ "$(stat -c %U:%G $file)" = 'root:root' ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "      * Wrong ownership for $file"
    logcheckresult "WARN" "Wrong ownership for $file"
    return
  fi
  info -c "$check"
  info "      * File not found"
  logcheckresult "INFO" "File not found"
}

check_3_23() {
  local id="3.23"
  local desc="确保 Containerd 套接字文件所有权设置为 root:root（自动）"
  local remediation="您应该运行以下命令：chown root:root /run/containerd/containerd.sock。这会将文件的所有权和组所有权设置为 root。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/run/containerd/containerd.sock"
  if [ -S "$file" ]; then
    if [ "$(stat -c %U:%G $file)" = 'root:root' ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "      * Wrong ownership for $file"
    logcheckresult "WARN" "Wrong ownership for $file"
    return
  fi
  info -c "$check"
  info "      * File not found"
  logcheckresult "INFO" "File not found"
}

check_3_24() {
  local id="3.24"
  local desc="确保 Containerd 套接字文件权限设置为 660 或更严格（自动）"
  local remediation="您应该运行以下命令：chmod 660 /run/containerd/containerd.sock。这会将此文件的文件权限设置为 660。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/run/containerd/containerd.sock"
  if [ -S "$file" ]; then
    if [ "$(stat -c %a $file)" -le 660 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    warn "      * Wrong permissions for $file"
    logcheckresult "WARN" "Wrong permissions for $file"
    return
  fi
  info -c "$check"
  info "      * File not found"
  logcheckresult "INFO" "File not found"
}

check_3_end() {
  endsectionjson
}
