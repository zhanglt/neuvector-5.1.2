#!/bin/bash

check_4() {
  logit ""
  local id="4"
  local desc="容器镜像和构建文件"
  checkHeader="$id - $desc"
  info "$checkHeader"
  startsectionjson "$id" "$desc"
}

check_4_1() {
  local id="4.1"
  local desc="确保已为容器创建用户（自动）"
  local remediation="您应确保每个容器映像的 Dockerfile 包含以下信息：USER <username or ID>。如果容器基础镜像中没有创建特定用户，则在 Dockerfile 中的 USER 指令之前使用 useradd 命令添加特定用户。"
  local remediationImpact="以非 root 用户身份运行可能会给您带来挑战，您希望从底层主机绑定挂载卷。在这种情况下，应注意确保运行包含进程的用户可以根据他们的要求读取和写入绑定目录。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  # If container_users is empty, there are no running containers
  if [ -z "$containers" ]; then
    info -c "$check"
    info "     * No containers running"
    logcheckresult "INFO" "No containers running"
    return
  fi
  # We have some containers running, set failure flag to 0. Check for Users.
  fail=0
  # Make the loop separator be a new-line in POSIX compliant fashion
  set -f; IFS=$'
  '
  root_containers=""
  for c in $containers; do
    user=$(docker inspect --format 'User={{.Config.User}}' "$c")

    if [ "$user" = "User=0" ] || [ "$user" = "User=root" ] || [ "$user" = "User=" ] || [ "$user" = "User=[]" ] || [ "$user" = "User=<no value>" ]; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "     * Running as root: $c"
        root_containers="$root_containers $c"
        fail=1
        continue
      fi
      warn "     * Running as root: $c"
      root_containers="$root_containers $c"
    fi
  done
  # We went through all the containers and found none running as root
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "running as root" "$root_containers"
  # Make the loop separator go back to space
  set +f; unset IFS
}

check_4_2() {
  local id="4.2"
  local desc="确保容器只使用可信的基础镜像（手动）"
  local remediation="配置和使用 Docker 内容信任。查看每个 Docker 映像的历史记录以评估其风险，具体取决于您希望使用它部署的应用程序的敏感性。定期扫描 Docker 映像中的漏洞。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "NOTE"
}

check_4_3() {
  local id="4.3"
  local desc="确保容器中没有安装不必要的包（手动）"
  local remediation="您不应在容器内安装任何不需要的东西。如果可以，您应该考虑使用最小的基础镜像。一些可用的选项包括 BusyBox 和 Alpine。这不仅可以大大减少您的图像大小，而且还可以减少可能包含攻击向量的软件。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "NOTE"
}

check_4_4() {
  local id="4.4"
  local desc="确保图像被扫描并重建以包含安全补丁（手动）"
  local remediation="应重建映像以确保使用最新版本的基础映像，以将操作系统补丁级别保持在适当的级别。重新构建镜像后，应使用更新后的镜像重新启动容器。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "NOTE"
}

check_4_5() {
  local id="4.5"
  local desc="确保启用 Docker 的内容信任（自动）"
  local remediation="使用命令 echo DOCKER_CONTENT_TRUST=1 | 将 DOCKER_CONTENT_TRUST 变量添加到 /etc/environment 文件中sudo tee -a /etc/environment."
  local remediationImpact="这会阻止用户使用标记的图像，除非它们包含签名。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if [ "$DOCKER_CONTENT_TRUST" = "1" ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  warn -s "$check"
  logcheckresult "WARN"
}

check_4_6() {
  local id="4.6"
  local desc="确保已将 HEALTHCHECK 指令添加到容器映像（自动）"
  local remediation="您应该遵循 Docker 文档并重建您的容器映像以包含 HEALTHCHECK 指令。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  no_health_images=""
  for img in $images; do
    if docker inspect --format='{{.Config.Healthcheck}}' "$img" 2>/dev/null | grep -e "<nil>" >/dev/null 2>&1; then
      if [ $fail -eq 0 ]; then
        fail=1
        warn -s "$check"
      fi
      imgName=$(docker inspect --format='{{.RepoTags}}' "$img" 2>/dev/null)
      if ! [ "$imgName" = '[]' ]; then
        warn "     * No Healthcheck found: $imgName"
        no_health_images="$no_health_images $imgName"
      else
        warn "     * No Healthcheck found: $img"
        no_health_images="$no_health_images $img"
      fi
    fi
  done
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Images w/o HEALTHCHECK" "$no_health_images"
}

check_4_7() {
  local id="4.7"
  local desc="确保更新指令不在 Dockerfile 中单独使用（手动）"
  local remediation="在安装它们时，您应该将更新说明与安装说明和软件包的版本固定一起使用。这可以防止缓存并强制提取所需的版本。或者，您可以在 docker 构建过程中使用 --no-cache 标志来避免使用缓存层。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  update_images=""
  for img in $images; do
    if docker history "$img" 2>/dev/null | grep -e "update" >/dev/null 2>&1; then
      if [ $fail -eq 0 ]; then
        fail=1
        info -c "$check"
      fi
      imgName=$(docker inspect --format='{{.RepoTags}}' "$img" 2>/dev/null)
      if ! [ "$imgName" = '[]' ]; then
        info "     * Update instruction found: $imgName"
        update_images="$update_images $imgName"
      fi
    fi
  done
  if [ $fail -eq 0 ]; then
    pass -c "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "INFO" "Update instructions found" "$update_images"
}

check_4_8() {
  local id="4.8"
  local desc="确保删除 setuid 和 setgid 权限（手动）"
  local remediation="您应该只在需要它们的可执行文件上允许 setuid 和 setgid 权限。您可以在构建时通过在 Dockerfile 中添加以下命令来删除这些权限，最好是在 Dockerfile 的末尾： RUN find / -perm /6000 -type f -exec chmod a-s {} ; ||真的"
  local remediationImpact="上面的命令会破坏所有依赖于 setuid 或 setgid 权限的可执行文件，包括合法的。因此，您应该小心修改命令以满足您的要求，以免过度降低合法程序的权限。因此，在进行此类修改之前，您应该保持一定程度的谨慎并仔细检查所有进程，以避免中断。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "NOTE"
}

check_4_9() {
  local id="4.9"
  local desc="确保在 Dockerfiles 中使用 COPY 而不是 ADD（手动）"
  local remediation="您应该在 Dockerfile 中使用 COPY 而不是 ADD 指令。"
  local remediationImpact="如果应用程序需要作为 ADD 指令的一部分的功能，例如，如果您需要从远程 URLS 检索文件，则在实现此控件时需要小心。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  add_images=""
  for img in $images; do
    if docker history --format "{{ .CreatedBy }}" --no-trunc "$img" | \
      sed '$d' | grep -q 'ADD'; then
      if [ $fail -eq 0 ]; then
        fail=1
        info -c "$check"
      fi
      imgName=$(docker inspect --format='{{.RepoTags}}' "$img" 2>/dev/null)
      if ! [ "$imgName" = '[]' ]; then
        info "     * ADD in image history: $imgName"
        add_images="$add_images $imgName"
      fi
    fi
  done
  if [ $fail -eq 0 ]; then
    pass -c "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "INFO" "Images using ADD" "$add_images"
}

check_4_10() {
  local id="4.10"
  local desc="确保机密未存储在 Dockerfile 中（手动）"
  local remediation="不要在 Dockerfile 中存储任何类型的秘密。如果在构建过程中需要机密，请使用机密管理工具，例如 Docker 中包含的 buildkit 构建器。"
  local remediationImpact="Docker 镜像构建需要一个适当的秘密管理过程。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "NOTE"
}

check_4_11() {
  local id="4.11"
  local desc="确保只安装经过验证的包（手动）"
  local remediation="您应该使用您选择的安全包分发机制来确保软件包的真实性。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "NOTE"
}

check_4_12() {
  local id="4.12"
  local desc="确保所有签名的工件都经过验证（手动）"
  local remediation="在上传到包注册表之前验证工件签名。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "NOTE"
}

check_4_end() {
  endsectionjson
}
#!/bin/bash

check_4() {
  logit ""
  local id="4"
  local desc="容器镜像和构建文件"
  checkHeader="$id - $desc"
  info "$checkHeader"
  startsectionjson "$id" "$desc"
}

check_4_1() {
  local id="4.1"
  local desc="确保已为容器创建用户（自动）"
  local remediation="您应确保每个容器映像的 Dockerfile 包含以下信息：USER <username or ID>。如果容器基础镜像中没有创建特定用户，则在 Dockerfile 中的 USER 指令之前使用 useradd 命令添加特定用户。"
  local remediationImpact="以非 root 用户身份运行可能会给您带来挑战，您希望从底层主机绑定挂载卷。在这种情况下，应注意确保运行包含进程的用户可以根据他们的要求读取和写入绑定目录。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  # If container_users is empty, there are no running containers
  if [ -z "$containers" ]; then
    info -c "$check"
    info "     * No containers running"
    logcheckresult "INFO" "No containers running"
    return
  fi
  # We have some containers running, set failure flag to 0. Check for Users.
  fail=0
  # Make the loop separator be a new-line in POSIX compliant fashion
  set -f; IFS=$'
  '
  root_containers=""
  for c in $containers; do
    user=$(docker inspect --format 'User={{.Config.User}}' "$c")

    if [ "$user" = "User=0" ] || [ "$user" = "User=root" ] || [ "$user" = "User=" ] || [ "$user" = "User=[]" ] || [ "$user" = "User=<no value>" ]; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "     * Running as root: $c"
        root_containers="$root_containers $c"
        fail=1
        continue
      fi
      warn "     * Running as root: $c"
      root_containers="$root_containers $c"
    fi
  done
  # We went through all the containers and found none running as root
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "running as root" "$root_containers"
  # Make the loop separator go back to space
  set +f; unset IFS
}

check_4_2() {
  local id="4.2"
  local desc="确保容器只使用可信的基础镜像（手动）"
  local remediation="配置和使用 Docker 内容信任。查看每个 Docker 映像的历史记录以评估其风险，具体取决于您希望使用它部署的应用程序的敏感性。定期扫描 Docker 映像中的漏洞。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "NOTE"
}

check_4_3() {
  local id="4.3"
  local desc="确保容器中没有安装不必要的包（手动）"
  local remediation="您不应在容器内安装任何不需要的东西。如果可以，您应该考虑使用最小的基础镜像。一些可用的选项包括 BusyBox 和 Alpine。这不仅可以大大减少您的图像大小，而且还可以减少可能包含攻击向量的软件。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "NOTE"
}

check_4_4() {
  local id="4.4"
  local desc="确保图像被扫描并重建以包含安全补丁（手动）"
  local remediation="应重建映像以确保使用最新版本的基础映像，以将操作系统补丁级别保持在适当的级别。重新构建镜像后，应使用更新后的镜像重新启动容器。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "NOTE"
}

check_4_5() {
  local id="4.5"
  local desc="确保启用 Docker 的内容信任（自动）"
  local remediation="使用命令 echo DOCKER_CONTENT_TRUST=1 | 将 DOCKER_CONTENT_TRUST 变量添加到 /etc/environment 文件中sudo tee -a /etc/environment."
  local remediationImpact="这会阻止用户使用标记的图像，除非它们包含签名。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  if [ "$DOCKER_CONTENT_TRUST" = "1" ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  warn -s "$check"
  logcheckresult "WARN"
}

check_4_6() {
  local id="4.6"
  local desc="确保已将 HEALTHCHECK 指令添加到容器映像（自动）"
  local remediation="您应该遵循 Docker 文档并重建您的容器映像以包含 HEALTHCHECK 指令。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  no_health_images=""
  for img in $images; do
    if docker inspect --format='{{.Config.Healthcheck}}' "$img" 2>/dev/null | grep -e "<nil>" >/dev/null 2>&1; then
      if [ $fail -eq 0 ]; then
        fail=1
        warn -s "$check"
      fi
      imgName=$(docker inspect --format='{{.RepoTags}}' "$img" 2>/dev/null)
      if ! [ "$imgName" = '[]' ]; then
        warn "     * No Healthcheck found: $imgName"
        no_health_images="$no_health_images $imgName"
      else
        warn "     * No Healthcheck found: $img"
        no_health_images="$no_health_images $img"
      fi
    fi
  done
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Images w/o HEALTHCHECK" "$no_health_images"
}

check_4_7() {
  local id="4.7"
  local desc="确保更新指令不在 Dockerfile 中单独使用（手动）"
  local remediation="在安装它们时，您应该将更新说明与安装说明和软件包的版本固定一起使用。这可以防止缓存并强制提取所需的版本。或者，您可以在 docker 构建过程中使用 --no-cache 标志来避免使用缓存层。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  update_images=""
  for img in $images; do
    if docker history "$img" 2>/dev/null | grep -e "update" >/dev/null 2>&1; then
      if [ $fail -eq 0 ]; then
        fail=1
        info -c "$check"
      fi
      imgName=$(docker inspect --format='{{.RepoTags}}' "$img" 2>/dev/null)
      if ! [ "$imgName" = '[]' ]; then
        info "     * Update instruction found: $imgName"
        update_images="$update_images $imgName"
      fi
    fi
  done
  if [ $fail -eq 0 ]; then
    pass -c "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "INFO" "Update instructions found" "$update_images"
}

check_4_8() {
  local id="4.8"
  local desc="确保删除 setuid 和 setgid 权限（手动）"
  local remediation="您应该只在需要它们的可执行文件上允许 setuid 和 setgid 权限。您可以在构建时通过在 Dockerfile 中添加以下命令来删除这些权限，最好是在 Dockerfile 的末尾： RUN find / -perm /6000 -type f -exec chmod a-s {} ; ||真的"
  local remediationImpact="上面的命令会破坏所有依赖于 setuid 或 setgid 权限的可执行文件，包括合法的。因此，您应该小心修改命令以满足您的要求，以免过度降低合法程序的权限。因此，在进行此类修改之前，您应该保持一定程度的谨慎并仔细检查所有进程，以避免中断。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "NOTE"
}

check_4_9() {
  local id="4.9"
  local desc="确保在 Dockerfiles 中使用 COPY 而不是 ADD（手动）"
  local remediation="您应该在 Dockerfile 中使用 COPY 而不是 ADD 指令。"
  local remediationImpact="如果应用程序需要作为 ADD 指令的一部分的功能，例如，如果您需要从远程 URLS 检索文件，则在实现此控件时需要小心。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  add_images=""
  for img in $images; do
    if docker history --format "{{ .CreatedBy }}" --no-trunc "$img" | \
      sed '$d' | grep -q 'ADD'; then
      if [ $fail -eq 0 ]; then
        fail=1
        info -c "$check"
      fi
      imgName=$(docker inspect --format='{{.RepoTags}}' "$img" 2>/dev/null)
      if ! [ "$imgName" = '[]' ]; then
        info "     * ADD in image history: $imgName"
        add_images="$add_images $imgName"
      fi
    fi
  done
  if [ $fail -eq 0 ]; then
    pass -c "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckre