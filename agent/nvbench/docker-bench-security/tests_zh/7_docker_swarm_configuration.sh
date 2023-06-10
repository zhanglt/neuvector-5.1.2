#!/bin/bash

check_7() {
  logit ""
  local id="7"
  local desc="Docker 集群配置"
  checkHeader="$id - $desc"
  info "$checkHeader"
  startsectionjson "$id" "$desc"
}

check_7_1() {
  local id="7.1"
  local desc="确保群模式未启用，如果不需要（自动）"
  local remediation="如果错误地在系统上启用了 swarm 模式，您应该运行命令：docker swarm leave"
  local remediationImpact="禁用 swarm 模式将影响正在使用的 Docker Enterprise 组件的操作。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if docker info 2>/dev/null | grep -e "Swarm:*\sinactive\s*" >/dev/null 2>&1; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  warn -s "$check"
  logcheckresult "WARN"
}

check_7_2() {
  local id="7.2"
  local desc="确保在 swarm 中创建了最少数量的管理器节点（自动）"
  local remediation="如果配置了过多的manager，可以使用命令将多余的节点降级为worker：docker node demote <manager node ID to be demoted>"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if docker info 2>/dev/null | grep -e "Swarm:*\sactive\s*" >/dev/null 2>&1; then
    managernodes=$(docker node ls | grep -c "Leader")
    if [ "$managernodes" -eq 1 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  pass -s "$check (Swarm mode not enabled)"
  logcheckresult "PASS"
}

check_7_3() {
  local id="7.3"
  local desc="确保 swarm 服务绑定到特定的主机接口（自动）"
  local remediation="解决这个问题需要重新初始化 swarm，为 --listen-addr 参数指定一个特定的接口。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if docker info 2>/dev/null | grep -e "Swarm:*\sactive\s*" >/dev/null 2>&1; then
    $netbin -lnt | grep -e '\[::]:2377 ' -e ':::2377' -e '*:2377 ' -e ' 0\.0\.0\.0:2377 ' >/dev/null 2>&1
    if [ $? -eq 1 ]; then
      pass -s "$check"
      logcheckresult "PASS"
      return
    fi
    warn -s "$check"
    logcheckresult "WARN"
    return
  fi
  pass -s "$check (Swarm mode not enabled)"
  logcheckresult "PASS"
}

check_7_4() {
  local id="7.4"
  local desc="确保所有 Docker 群覆盖网络都已加密（自动）"
  local remediation="您应该使用 --opt encrypted 标志创建覆盖网络。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  unencrypted_networks=""
  for encnet in $(docker network ls --filter driver=overlay --quiet); do
    if docker network inspect --format '{{.Name}} {{ .Options }}' "$encnet" | \
      grep -v 'encrypted:' 2>/dev/null 1>&2; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        fail=1
      fi
      warn "     * Unencrypted overlay network: $(docker network inspect --format '{{ .Name }} ({{ .Scope }})' "$encnet")"
      unencrypted_networks="$unencrypted_networks $(docker network inspect --format '{{ .Name }} ({{ .Scope }})' "$encnet")"
    fi
  done
  # We went through all the networks and found none that are unencrypted
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Unencrypted overlay networks:" "$unencrypted_networks"
}

check_7_5() {
  local id="7.5"
  local desc="确保 Docker 的秘密管理命令用于管理 swarm 集群中的秘密（手动）"
  local remediation="您应该遵循 docker secret 文档并使用它来有效地管理秘密。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if docker info 2>/dev/null | grep -e "Swarm:\s*active\s*" >/dev/null 2>&1; then
    if [ "$(docker secret ls -q | wc -l)" -ge 1 ]; then
      pass -c "$check"
      logcheckresult "PASS"
      return
    fi
    info -c "$check"
    logcheckresult "INFO"
    return
  fi
  pass -c "$check (Swarm mode not enabled)"
  logcheckresult "PASS"
}

check_7_6() {
  local id="7.6"
  local desc="确保群管理器在自动锁定模式下运行（自动）"
  local remediation="如果您正在初始化群，请使用命令：docker swarm init --autolock。如果要在现有的群管理器节点上设置 --autolock，请使用命令：docker swarm update --autolock。"
  local remediationImpact="如果没有管理员手动干预输入解锁密钥，处于自动锁定模式的集群将无法从重启中恢复。这可能并不总是可取的，应该在政策层面进行审查。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if docker info 2>/dev/null | grep -e "Swarm:\s*active\s*" >/dev/null 2>&1; then
    if ! docker swarm unlock-key 2>/dev/null | grep 'SWMKEY' 2>/dev/null 1>&2; then
      warn -s "$check"
      logcheckresult "WARN"
      return
    fi
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  pass -s "$check (Swarm mode not enabled)"
  logcheckresult "PASS"
}

check_7_7() {
  local id="7.7"
  local desc="确保集群管理器自动锁定密钥定期轮换​​（手动）"
  local remediation="您应该运行命令 docker swarm unlock-key --rotate 来轮换密钥。为了便于审核此建议，您应该维护密钥轮换记录并确保您建立预定义的密钥轮换频率。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if docker info 2>/dev/null | grep -e "Swarm:\s*active\s*" >/dev/null 2>&1; then
    note -c "$check"
    logcheckresult "NOTE"
    return
  fi
  pass -c "$check (Swarm mode not enabled)"
  logcheckresult "PASS"
}

check_7_8() {
  local id="7.8"
  local desc="确保适当轮换节点证书（手动）"
  local remediation="您应该运行命令 docker swarm update --cert-expiry 48h 以在节点证书上设置所需的到期时间。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if docker info 2>/dev/null | grep -e "Swarm:\s*active\s*" >/dev/null 2>&1; then
    if docker info 2>/dev/null | grep "Expiry Duration: 2 days"; then
      pass -c "$check"
      logcheckresult "PASS"
      return
    fi
    info -c "$check"
    logcheckresult "INFO"
    return
  fi
  pass -c "$check (Swarm mode not enabled)"
  logcheckresult "PASS"
}

check_7_9() {
  local id="7.9"
  local desc="确保适当轮换 CA 证书（手动）"
  local remediation="您应该运行命令 docker swarm ca --rotate 来轮换证书。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if docker info 2>/dev/null | grep -e "Swarm:\s*active\s*" >/dev/null 2>&1; then
    info -c "$check"
    logcheckresult "INFO"
    return
  fi
  pass -c "$check (Swarm mode not enabled)"
  logcheckresult "PASS"
}

check_7_10() {
  local id="7.10"
  local desc="确保管理平面流量与数据平面流量分开（手动）"
  local remediation="您应该分别使用管理平面和数据平面的专用接口来初始化 swarm。示例：docker swarm init --advertise-addr=192.168.0.1 --data-path-addr=17.1.0.3"
  local remediationImpact="这需要每个节点有两个网络接口。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if docker info 2>/dev/null | grep -e "Swarm:\s*active\s*" >/dev/null 2>&1; then
    info -c "$check"
    logcheckresult "INFO"
    return
  fi
  pass -c "$check (Swarm mode not enabled)"
  logcheckresult "PASS"
}

check_7_end() {
  endsectionjson
}
