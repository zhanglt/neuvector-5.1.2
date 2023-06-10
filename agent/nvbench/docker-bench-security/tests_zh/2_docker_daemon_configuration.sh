#!/bin/bash

check_2() {
  logit ""
  local id="2"
  local desc="Docker 守护进程配置"
  checkHeader="$id - $desc"
  info "$checkHeader"
  startsectionjson "$id" "$desc"
}

check_2_1() {
  local id="2.1"
  local desc="如果可能，以非 root 用户身份运行 Docker 守护进程（手动）"
  local remediation="按照当前的 Docker 文档了解如何以非根用户身份安装 Docker 守护进程。"
  local remediationImpact="有多个先决条件，具体取决于正在使用的发行版，以及有关网络和资源限制的已知限制。在无根模式下运行还会更改任何正在使用的配置文件的位置，包括所有使用守护程序的容器。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "INFO"
}

check_2_2() {
  local id="2.2"
  local desc="确保默认网桥上的容器之间的网络流量受到限制（计分）"
  local remediation="编辑 Docker 守护程序配置文件以确保禁用容器间通信：icc: false。"
  local remediationImpact="默认网桥上禁用容器间通信。如果需要在同一主机上的容器之间进行任何通信，则需要使用容器链接或自定义网络明确定义。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if get_docker_effective_command_line_args '--icc' | grep false >/dev/null 2>&1; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  if get_docker_configuration_file_args 'icc' | grep "false" >/dev/null 2>&1; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  warn -s "$check"
  logcheckresult "WARN"
}

check_2_3() {
  local id="2.3"
  local desc="确保日志记录级别设置为“信息”（计分）"
  local remediation="确保 Docker 守护程序配置文件具有以下配置，包括日志级别：信息。或者，按以下方式运行 Docker 守护进程：dockerd --log-level=info"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if get_docker_configuration_file_args 'log-level' >/dev/null 2>&1; then
    if get_docker_configuration_file_args 'log-level' | grep info >/dev/null 2>&1; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    if [ -z "$(get_docker_configuration_file_args 'log-level')" ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  if get_docker_effective_command_line_args '-l'; then
    if get_docker_effective_command_line_args '-l' | grep "info" >/dev/null 2>&1; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  pass -s "$check"
  logcheckresult "PASS"
}

check_2_4() {
  local id="2.4"
  local desc="确保允许 Docker 对 iptables 进行更改（已评分）"
  local remediation="不要使用 --iptables=false 选项运行 Docker 守护进程。"
  local remediationImpact="Docker 守护进程服务需要在启动前启用 iptables 规则。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if get_docker_effective_command_line_args '--iptables' | grep "false" >/dev/null 2>&1; then
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  if get_docker_configuration_file_args 'iptables' | grep "false" >/dev/null 2>&1; then
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  pass -s "$check"
  logcheckresult "PASS"
}

check_2_5() {
  local id="2.5"
  local desc="确保不使用不安全的注册表（评分）"
  local remediation="您应该确保没有使用不安全的注册表。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if get_docker_effective_command_line_args '--insecure-registry' | grep "insecure-registry" >/dev/null 2>&1; then
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  if ! [ -z "$(get_docker_configuration_file_args 'insecure-registries')" ]; then
    if get_docker_configuration_file_args 'insecure-registries' | grep '\[]' >/dev/null 2>&1; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  pass -s "$check"
  logcheckresult "PASS"
}

check_2_6() {
  local id="2.6"
  local desc="确保未使用 aufs 存储驱动程序（计分）"
  local remediation="不要使用 dockerd --storage-driver aufs 选项启动 Docker 守护进程。"
  local remediationImpact="aufs 是唯一允许容器共享可执行文件和共享库内存的存储驱动程序。它的使用应该根据您组织的安全策略进行审查。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if docker info 2>/dev/null | grep -e "^\sStorage Driver:\s*aufs\s*$" >/dev/null 2>&1; then
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  pass -s "$check"
  logcheckresult "PASS"
}

check_2_7() {
  local id="2.7"
  local desc="确保为 Docker 守护程序配置 TLS 身份验证（已评分）"
  local remediation="按照 Docker 文档或其他参考资料中提到的步骤进行操作。缺省情况下，没有配置 TLS 认证。"
  local remediationImpact="您需要管理和保护 Docker 守护程序和 Docker 客户端的证书和密钥。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if $(grep -qE "host.*tcp://" "$CONFIG_FILE") || \
    [ $(get_docker_cumulative_command_line_args '-H' | grep -vE '(unix|fd)://') > /dev/null 2>&1 ]; then
    if [ $(get_docker_configuration_file_args '"tlsverify":' | grep 'true') ] || \
        [ $(get_docker_cumulative_command_line_args '--tlsverify' | grep 'tlsverify') >/dev/null 2>&1 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    if [ $(get_docker_configuration_file_args '"tls":' | grep 'true') ] || \
        [ $(get_docker_cumulative_command_line_args '--tls' | grep 'tls$') >/dev/null 2>&1 ]; then
      warn -s "$check"
      warn "     * Docker daemon currently listening on TCP with TLS, but no verification"
      logcheckresult "WARN" "Docker daemon currently listening on TCP with TLS, but no verification"
      return
    fi
    warn -s "$check"
    warn "     * Docker daemon currently listening on TCP without TLS"
    logcheckresult "WARN" "Docker daemon currently listening on TCP without TLS"
    return
  fi
  info -c "$check"
  info "     * Docker daemon not listening on TCP"
  logcheckresult "INFO" "Docker daemon not listening on TCP"
}

check_2_8() {
  local id="2.8"
  local desc="确保默认的 ulimit 配置正确（手动）"
  local remediation="在守护程序模式下运行 Docker，并根据您的环境并根据您的安全策略将 --default-ulimit 作为选项与相应的 ulimit 一起传递。示例：dockerd --default-ulimit nproc=1024:2048 --default-ulimit nofile=100:200"
  local remediationImpact="如果 ulimits 设置不正确，这可能会导致系统资源出现问题，并可能导致拒绝服务情况。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if get_docker_configuration_file_args 'default-ulimit' | grep -v '{}' >/dev/null 2>&1; then
    pass -c "$check"
    logcheckresult "PASS"
    return
  fi
  if get_docker_effective_command_line_args '--default-ulimit' | grep "default-ulimit" >/dev/null 2>&1; then
    pass -c "$check"
    logcheckresult "PASS"
    return
  fi
  info -c "$check"
  info "     * Default ulimit doesn't appear to be set"
  logcheckresult "INFO" "Default ulimit doesn't appear to be set"
}

check_2_9() {
  local id="2.9"
  local desc="启用用户命名空间支持（计分）"
  local remediation="请查阅 Docker 文档，了解可根据您的要求进行配置的各种方式。高级步骤是： 确保文件 /etc/subuid 和 /etc/subgid 存在。使用 --userns-remap 标志启动 docker 守护进程。"
  local remediationImpact="用户命名空间重新映射与许多 Docker 功能不兼容，目前还破坏了它的一些功能。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if get_docker_configuration_file_args 'userns-remap' | grep -v '""'; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  if get_docker_effective_command_line_args '--userns-remap' | grep "userns-remap" >/dev/null 2>&1; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  warn -s "$check"
  logcheckresult "WARN"
}

check_2_10() {
  local id="2.10"
  local desc="确保已确认默认 cgroup 使用情况（已评分）"
  local remediation="默认设置符合良好的安全惯例，可以保留在原位。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if get_docker_configuration_file_args 'cgroup-parent' | grep -v ''; then
    warn -s "$check"
    info "     * Confirm cgroup usage"
    logcheckresult "WARN" "Confirm cgroup usage"
    return
  fi
  if get_docker_effective_command_line_args '--cgroup-parent' | grep "cgroup-parent" >/dev/null 2>&1; then
    warn -s "$check"
    info "     * Confirm cgroup usage"
    logcheckresult "WARN" "Confirm cgroup usage"
    return
  fi
  pass -s "$check"
  logcheckresult "PASS"
}

check_2_11() {
  local id="2.11"
  local desc="确保基本设备大小在需要之前不会更改（计分）"
  local remediation="除非需要，否则不要设置 --storage-opt dm.basesize。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if get_docker_configuration_file_args 'storage-opts' | grep "dm.basesize" >/dev/null 2>&1; then
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  if get_docker_effective_command_line_args '--storage-opt' | grep "dm.basesize" >/dev/null 2>&1; then
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  pass -s "$check"
  logcheckresult "PASS"
}

check_2_12() {
  local id="2.12"
  local desc="确保启用 Docker 客户端命令的授权（已评分）"
  local remediation="安装/创建授权插件。根据需要配置授权策略。使用命令 dockerd --authorization-plugin=<PLUGIN_ID> 启动 docker 守护进程"
  local remediationImpact="每个 Docker 命令都需要通过授权插件机制。这可能会影响性能"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if get_docker_configuration_file_args 'authorization-plugins' | grep -v '\[]'; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  if get_docker_effective_command_line_args '--authorization-plugin' | grep "authorization-plugin" >/dev/null 2>&1; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  warn -s "$check"
  logcheckresult "WARN"
}

check_2_13() {
  local id="2.13"
  local desc="确保配置了集中和远程日志记录（计分）"
  local remediation="按照其文档设置所需的日志驱动程序。使用该日志记录驱动程序启动 docker 守护进程。示例：dockerd --log-driver=syslog --log-opt syslog-address=tcp://192.xxx.xxx.xxx"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if docker info --format '{{ .LoggingDriver }}' | grep 'json-file' >/dev/null 2>&1; then
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  pass -s "$check"
  logcheckresult "PASS"
}

check_2_14() {
  local id="2.14"
  local desc="确保容器被限制获得新的特权（计分）"
  local remediation="您应该使用命令运行 Docker 守护进程：dockerd --no-new-privileges"
  local remediationImpact="no_new_priv 防止 SELinux 等 LSM 提升单个容器的权限。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if get_docker_effective_command_line_args '--no-new-privileges' | grep "no-new-privileges" >/dev/null 2>&1; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  if get_docker_configuration_file_args 'no-new-privileges' | grep true >/dev/null 2>&1; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  warn -s "$check"
  logcheckresult "WARN"
}

check_2_15() {
  local id="2.15"
  local desc="确保启用实时恢复（计分）"
  local remediation="以守护进程模式运行 Docker 并传递 --live-restore 选项。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if docker info 2>/dev/null | grep -e "Live Restore Enabled:\s*true\s*" >/dev/null 2>&1; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  if docker info 2>/dev/null | grep -e "Swarm:*\sactive\s*" >/dev/null 2>&1; then
    pass -s "$check (Incompatible with swarm mode)"
    logcheckresult "PASS"
    return
  fi
  if get_docker_effective_command_line_args '--live-restore' | grep "live-restore" >/dev/null 2>&1; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  warn -s "$check"
  logcheckresult "WARN"
}

check_2_16() {
  local id="2.16"
  local desc="确保禁用 Userland 代理（计分）"
  local remediation="您应该使用命令运行 Docker 守护进程：dockerd --userland-proxy=false"
  local remediationImpact="某些具有较旧 Linux 内核的系统可能无法支持发夹 NAT，因此需要用户态代理服务。此外，一些网络设置可能会受到删除用户空间代理的影响。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if get_docker_configuration_file_args 'userland-proxy' | grep false >/dev/null 2>&1; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  if get_docker_effective_command_line_args '--userland-proxy=false' 2>/dev/null | grep "userland-proxy=false" >/dev/null 2>&1; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  warn -s "$check"
  logcheckresult "WARN"
}

check_2_17() {
  local id="2.17"
  local desc="确保在适当的情况下应用守护程序范围的自定义 seccomp 配置文件（手动）"
  local remediation="默认情况下，应用 Docker 的默认 seccomp 配置文件。如果这足以满足您的环境，则无需执行任何操作。"
  local remediationImpact="错误配置的 seccomp 配置文件可能会中断您的容器环境。因此，如果您选择覆盖默认设置，您应该格外小心。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if docker info --format '{{ .SecurityOptions }}' | grep 'name=seccomp,profile=default' 2>/dev/null 1>&2; then
    pass -c "$check"
    logcheckresult "PASS"
    return
  fi
  info -c "$check"
  logcheckresult "INFO"
}

check_2_18() {
  docker_version=$(docker version | grep -i -A2 '^server' | grep ' Version:' \
    | awk '{print $NF; exit}' | tr -d '[:alpha:]-,.' | cut -c 1-4)

  local id="2.18"
  local desc="确保实验性功能未在生产中实现（计分）"
  local remediation="您不应将 --experimental 作为运行时参数传递给生产系统上的 Docker 守护程序。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if [ "$docker_version" -le 1903 ]; then
    if docker version -f '{{.Server.Experimental}}' | grep false 2>/dev/null 1>&2; then
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
  info -c "$desc"
  logcheckresult "INFO"
}

check_2_end() {
  endsectionjson
}
