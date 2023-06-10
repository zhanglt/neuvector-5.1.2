#!/bin/bash

check_8() {
  logit ""
  local id="8"
  local desc="Docker 企业配置"
  checkHeader="$id - $desc"
  info "$checkHeader"
  startsectionjson "$id" "$desc"
}

check_product_license() {
  enterprise_license=1
  if docker version | grep -Eqi '^Server.*Community$|Version.*-ce$'; then
    info "  * Community Engine license, skipping section 8"
    enterprise_license=0
  fi
}

check_8_1() {
  if [ "$enterprise_license" -ne 1 ]; then
    return
  fi

  local id="8.1"
  local desc="通用控制平面配置"
  local check="$id - $desc"
  info "$check"
}

check_8_1_1() {
  if [ "$enterprise_license" -ne 1 ]; then
    return
  fi

  local id="8.1.1"
  local desc="配置 LDAP 身份验证服务（自动）"
  local remediation="您可以通过 UCP 管理设置 UI 配置 LDAP 集成。也可以通过配置文件启用 LDAP 集成"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "INFO"
}

check_8_1_2() {
  if [ "$enterprise_license" -ne 1 ]; then
    return
  fi

  local id="8.1.2"
  local desc="使用外部证书（自动）"
  local remediation="您可以在安装期间或安装后通过 UCP 管理设置用户界面为 UCP 配置自己的证书。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "INFO"
}

check_8_1_3() {
  if [ "$enterprise_license" -ne 1 ]; then
    return
  fi

  local id="8.1.3"
  local desc="强制非特权用户使用客户端证书包（未评分）"
  local remediation="可以通过以下两种方式之一创建客户端证书包。用户管理 UI：UCP 管理员可以代表用户提供客户端证书包。自配置：有权访问 UCP 控制台的用户可以自己创建客户端证书包。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "INFO"
}

check_8_1_4() {
  if [ "$enterprise_license" -ne 1 ]; then
    return
  fi

  local id="8.1.4"
  local desc="配置适用的基于集群角色的访问控制策略（未评分）"
  local remediation="UCP RBAC 组件可以根据需要通过 UCP 用户管理 UI 配置。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "INFO"
}

check_8_1_5() {
  if [ "$enterprise_license" -ne 1 ]; then
    return
  fi

  local id="8.1.5"
  local desc="启用签名图像实施（自动）"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "INFO"
}

check_8_1_6() {
  if [ "$enterprise_license" -ne 1 ]; then
    return
  fi

  local id="8.1.6"
  local desc="将每用户会话限制设置为“3”或更低的值（自动）"
  local remediation="检索 UCP API 令牌。检索并保存 UCP 配置。打开 ucp-config.toml 文件，将 [auth.sessions] 部分下的 per_user_limit 条目设置为 3 或更低但大于 0 的值。使用新配置更新 UCP。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "INFO"
}

check_8_1_7() {
  if [ "$enterprise_license" -ne 1 ]; then
    return
  fi

  local id="8.1.7"
  local desc="将“Lifetime Minutes”和“Renewal Threshold Minutes”值分别设置为“15”或更低和“0”（自动）"
  local remediation="检索 UCP API 令牌。检索并保存 UCP 配置。打开 ucp-config.toml 文件，将 [auth.sessions] 部分下的 lifetime_minutes 和 renewal_threshold_minutes 条目分别设置为 15 或更低的值和 0。使用新配置更新 UCP。"
  local remediationImpact="将 Lifetime Minutes 设置为太低的值会导致用户不得不不断地重新验证其 Docker Enterprise 集群。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "INFO"
}

check_8_2() {
  if [ "$enterprise_license" -ne 1 ]; then
    return
  fi

  local id="8.2"
  local desc="Docker 可信注册表配置"
  local check="$id - $desc"
  info "$check"
}

check_8_2_1() {
  if [ "$enterprise_license" -ne 1 ]; then
    return
  fi

  local id="8.2.1"
  local desc="启用图像漏洞扫描（自动）"
  local remediation="您可以导航到 DTR 设置 UI 并选择安全选项卡以访问图像扫描配置。选择启用扫描滑块以启用此功能。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "INFO"
}

check_8_end() {
  endsectionjson
}
