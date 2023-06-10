#!/bin/bash

check_5() {
  logit ""
  local id="5"
  local desc="容器运行时"
  checkHeader="$id - $desc"
  info "$checkHeader"
  startsectionjson "$id" "$desc"
}

check_running_containers() {
  # If containers is empty, there are no running containers
  if [ -z "$containers" ]; then
    info "  * No containers running, skipping Section 5"
    return
  fi
  # Make the loop separator be a new-line in POSIX compliant fashion
  set -f; IFS=$'
  '
}

check_5_1() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.1"
  local desc="确保启用 AppArmor 配置文件（如果适用）（自动）"
  local remediation="如果 AppArmor 适用于您的 Linux 操作系统，您应该启用它。或者，可以使用 Docker 的默认 AppArmor 策略。"
  local remediationImpact="该容器将具有 AppArmor 配置文件中定义的安全控制。需要注意的是，如果 AppArmor 配置文件配置错误，可能会导致容器运行出现问题。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  no_apparmor_containers=""
  for c in $containers; do
    policy=$(docker inspect --format 'AppArmorProfile={{ .AppArmorProfile }}' "$c")

    if [ "$policy" = "AppArmorProfile=" ] || [ "$policy" = "AppArmorProfile=[]" ] || [ "$policy" = "AppArmorProfile=<no value>" ] || [ "$policy" = "AppArmorProfile=unconfined" ]; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "     * No AppArmorProfile Found: $c"
        no_apparmor_containers="$no_apparmor_containers $c"
        fail=1
        continue
      fi
      warn "     * No AppArmorProfile Found: $c"
      no_apparmor_containers="$no_apparmor_containers $c"
    fi
  done
  # We went through all the containers and found none without AppArmor
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Containers with no AppArmorProfile" "$no_apparmor_containers"
}

check_5_2() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.2"
  local desc="确保设置了 SELinux 安全选项（如果适用）（自动）"
  local remediation="设置 SELinux 状态。设置 SELinux 策略。为 Docker 容器创建或导入 SELinux 策略模板。在启用 SELinux 的情况下以守护进程模式启动 Docker。使用安全选项启动 Docker 容器。"
  local remediationImpact="SELinux 策略中定义的任何限制都将应用于您的容器。需要注意的是，如果您的 SELinux 策略配置错误，这可能会对受影响容器的正确运行产生影响。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  no_securityoptions_containers=""
  for c in $containers; do
    policy=$(docker inspect --format 'SecurityOpt={{ .HostConfig.SecurityOpt }}' "$c")

    if [ "$policy" = "SecurityOpt=" ] || [ "$policy" = "SecurityOpt=[]" ] || [ "$policy" = "SecurityOpt=<no value>" ]; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "     * No SecurityOptions Found: $c"
        no_securityoptions_containers="$no_securityoptions_containers $c"
        fail=1
        continue
      fi
      warn "     * No SecurityOptions Found: $c"
      no_securityoptions_containers="$no_securityoptions_containers $c"
    fi
  done
  # We went through all the containers and found none without SELinux
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Containers with no SecurityOptions" "$no_securityoptions_containers"
}

check_5_3() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.3"
  local desc="确保 Linux 内核功能在容器内受到限制（自动）"
  local remediation="您可以删除所有当前配置的功能，然后仅恢复您专门使用的功能：docker run --cap-drop=all --cap-add={<Capability 1>,<Capability 2>} <Run arguments> <Container图像名称或 ID> <命令>"
  local remediationImpact="对容器内进程的限制基于哪些 Linux 功能有效。删除 NET_RAW 功能会阻止容器创建原始套接字，这在大多数情况下都是很好的安全实践，但可能会影响某些网络实用程序。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  caps_containers=""
  for c in $containers; do
    container_caps=$(docker inspect --format 'CapAdd={{ .HostConfig.CapAdd }}' "$c")
    caps=$(echo "$container_caps" | tr "[:lower:]" "[:upper:]" | \
      sed 's/CAPADD/CapAdd/' | \
      sed -r "s/CAP_AUDIT_WRITE|CAP_CHOWN|CAP_DAC_OVERRIDE|CAP_FOWNER|CAP_FSETID|CAP_KILL|CAP_MKNOD|CAP_NET_BIND_SERVICE|CAP_NET_RAW|CAP_SETFCAP|CAP_SETGID|CAP_SETPCAP|CAP_SETUID|CAP_SYS_CHROOT|\s//g" | \
      sed -r "s/AUDIT_WRITE|CHOWN|DAC_OVERRIDE|FOWNER|FSETID|KILL|MKNOD|NET_BIND_SERVICE|NET_RAW|SETFCAP|SETGID|SETPCAP|SETUID|SYS_CHROOT|\s//g")

    if [ "$caps" != 'CapAdd=' ] && [ "$caps" != 'CapAdd=[]' ] && [ "$caps" != 'CapAdd=<no value>' ] && [ "$caps" != 'CapAdd=<nil>' ]; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "     * Capabilities added: $caps to $c"
        caps_containers="$caps_containers $c"
        fail=1
        continue
      fi
      warn "     * Capabilities added: $caps to $c"
      caps_containers="$caps_containers $c"
    fi
  done
  # We went through all the containers and found none with extra capabilities
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Capabilities added for containers" "$caps_containers"
}

check_5_4() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.4"
  local desc="确保不使用特权容器（自动）"
  local remediation="您不应使用 --privileged 标志运行容器。"
  local remediationImpact="如果您在没有 --privileged 标志的情况下启动容器，它不会有过多的默认功能。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  privileged_containers=""
  for c in $containers; do
    privileged=$(docker inspect --format '{{ .HostConfig.Privileged }}' "$c")

    if [ "$privileged" = "true" ]; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "     * Container running in Privileged mode: $c"
        privileged_containers="$privileged_containers $c"
        fail=1
        continue
      fi
      warn "     * Container running in Privileged mode: $c"
      privileged_containers="$privileged_containers $c"
    fi
  done
  # We went through all the containers and found no privileged containers
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Containers running in privileged mode" "$privileged_containers"
}

check_5_5() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.5"
  local desc="确保敏感的主机系统目录未安装在容器上（自动）"
  local remediation="您不应在容器内的主机上挂载对安全敏感的目录，尤其是在读写模式下。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  # List of sensitive directories to test for. Script uses new-lines as a separator.
  # Note the lack of identation. It needs it for the substring comparison.
  sensitive_dirs='/
/boot
/dev
/etc
/lib
/proc
/sys
/usr'
  fail=0
  sensitive_mount_containers=""
  for c in $containers; do
    volumes=$(docker inspect --format '{{ .Mounts }}' "$c")
    if docker inspect --format '{{ .VolumesRW }}' "$c" 2>/dev/null 1>&2; then
      volumes=$(docker inspect --format '{{ .VolumesRW }}' "$c")
    fi
    # Go over each directory in sensitive dir and see if they exist in the volumes
    for v in $sensitive_dirs; do
      sensitive=0
      if echo "$volumes" | grep -e "{.*\s$v\s.*true\s.*}" 2>/tmp/null 1>&2; then
        sensitive=1
      fi
      if [ $sensitive -eq 1 ]; then
        # If it's the first container, fail the test
        if [ $fail -eq 0 ]; then
          warn -s "$check"
          warn "     * Sensitive directory $v mounted in: $c"
          sensitive_mount_containers="$sensitive_mount_containers $c:$v"
          fail=1
          continue
        fi
        warn "     * Sensitive directory $v mounted in: $c"
        sensitive_mount_containers="$sensitive_mount_containers $c:$v"
      fi
    done
  done
  # We went through all the containers and found none with sensitive mounts
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Containers with sensitive directories mounted" "$sensitive_mount_containers"
}

check_5_6() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.6"
  local desc="确保 sshd 不在容器内运行（自动）"
  local remediation="从容器中卸载 SSH 守护进程并使用 docker exec 进入远程主机上的容器。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  ssh_exec_containers=""
  printcheck=0
  for c in $containers; do

    processes=$(docker exec "$c" ps -el 2>/dev/null | grep -c sshd | awk '{print $1}')
    if [ "$processes" -ge 1 ]; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "     * Container running sshd: $c"
        ssh_exec_containers="$ssh_exec_containers $c"
        fail=1
        printcheck=1
      else
        warn "     * Container running sshd: $c"
        ssh_exec_containers="$ssh_exec_containers $c"
      fi
    fi

    exec_check=$(docker exec "$c" ps -el 2>/dev/null)
    if [ $? -eq 255 ]; then
        if [ $printcheck -eq 0 ]; then
          warn -s "$check"
          printcheck=1
        fi
      warn "     * Docker exec fails: $c"
      ssh_exec_containers="$ssh_exec_containers $c"
      fail=1
    fi

  done
  # We went through all the containers and found none with sshd
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Containers with sshd/docker exec failures" "$ssh_exec_containers"
}

check_5_7() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.7"
  local desc="确保特权端口未在容器内映射（自动）"
  local remediation="启动容器时，不应将容器端口映射到特权主机端口。您还应该确保没有这样的容器来托管 Dockerfile 中的特权端口映射声明。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  privileged_port_containers=""
  for c in $containers; do
    # Port format is private port -> ip: public port
    ports=$(docker port "$c" | awk '{print $0}' | cut -d ':' -f2)

    # iterate through port range (line delimited)
    for port in $ports; do
      if [ -n "$port" ] && [ "$port" -lt 1024 ]; then
        # If it's the first container, fail the test
        if [ $fail -eq 0 ]; then
          warn -s "$check"
          warn "     * Privileged Port in use: $port in $c"
          privileged_port_containers="$privileged_port_containers $c:$port"
          fail=1
          continue
        fi
        warn "     * Privileged Port in use: $port in $c"
        privileged_port_containers="$privileged_port_containers $c:$port"
      fi
    done
  done
  # We went through all the containers and found no privileged ports
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Containers using privileged ports" "$privileged_port_containers"
}

check_5_8() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.8"
  local desc="确保容器上只打开需要的端口（手动）"
  local remediation="您应该确保每个容器映像的 Dockerfile 仅公开所需的端口。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  open_port_containers=""
  for c in $containers; do
    ports=$(docker port "$c" | awk '{print $0}' | cut -d ':' -f2)

    for port in $ports; do
      if [ -n "$port" ]; then
        # If it's the first container, fail the test
        if [ $fail -eq 0 ]; then
          warn -s "$check"
          warn "     * Port in use: $port in $c"
          open_port_containers="$open_port_containers $c:$port"
          fail=1
          continue
        fi
        warn "     * Port in use: $port in $c"
        open_port_containers="$open_port_containers $c:$port"
      fi
    done
  done

  # We went through all the containers and found none with open ports
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Containers with open ports" "$open_port_containers"
}

check_5_9() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.9"
  local desc="确保主机的网络名称空间未共享（自动）"
  local remediation="启动任何容器时不应传递 --net=host 选项。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  net_host_containers=""
  for c in $containers; do
    mode=$(docker inspect --format 'NetworkMode={{ .HostConfig.NetworkMode }}' "$c")

    if [ "$mode" = "NetworkMode=host" ]; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "     * Container running with networking mode 'host': $c"
        net_host_containers="$net_host_containers $c"
        fail=1
        continue
      fi
      warn "     * Container running with networking mode 'host': $c"
      net_host_containers="$net_host_containers $c"
    fi
  done
  # We went through all the containers and found no Network Mode host
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Containers running with networking mode 'host'" "$net_host_containers"
}

check_5_10() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.10"
  local desc="确保容器的内存使用受到限制（自动）"
  local remediation="通过使用 --memory 参数，您应该只使用容器所需的内存来运行容器。"
  local remediationImpact="如果没有为每个容器设置正确的内存限制，一个进程可能会扩大其使用量并导致其他容器耗尽资源。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  mem_unlimited_containers=""
  for c in $containers; do
    memory=$(docker inspect --format '{{ .HostConfig.Memory }}' "$c")
    if docker inspect --format '{{ .Config.Memory }}' "$c" 2> /dev/null 1>&2; then
      memory=$(docker inspect --format '{{ .Config.Memory }}' "$c")
    fi

    if [ "$memory" = "0" ]; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "      * Container running without memory restrictions: $c"
        mem_unlimited_containers="$mem_unlimited_containers $c"
        fail=1
        continue
      fi
      warn "      * Container running without memory restrictions: $c"
      mem_unlimited_containers="$mem_unlimited_containers $c"
    fi
  done
  # We went through all the containers and found no lack of Memory restrictions
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Container running without memory restrictions" "$mem_unlimited_containers"
}

check_5_11() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.11"
  local desc="确保在容器上正确设置 CPU 优先级（自动）"
  local remediation="您应该根据容器在组织中的优先级来管理容器之间的 CPU 运行时。为此，使用 --cpu-shares 参数启动容器。"
  local remediationImpact="如果您没有正确分配 CPU 阈值，容器进程可能会耗尽资源并变得无响应。如果主机上的 CPU 资源不受限制，则 CPU 份额不会对单个资源施加任何限制。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  cpu_unlimited_containers=""
  for c in $containers; do
    cpushares=$(docker inspect --format '{{ .HostConfig.CpuShares }}' "$c")
    nanocpus=$(docker inspect --format '{{ .HostConfig.NanoCpus }}' "$c")

    if docker inspect --format '{{ .Config.CpuShares }}' "$c" 2> /dev/null 1>&2; then
      cpushares=$(docker inspect --format '{{ .Config.CpuShares }}' "$c")
      nanocpus=$(docker inspect --format '{{ .Config.NanoCpus }}' "$c")
    fi

    if [ "$cpushares" = "0" ] && [ "$nanocpus" = "0" ]; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "      * Container running without CPU restrictions: $c"
        cpu_unlimited_containers="$cpu_unlimited_containers $c"
        fail=1
        continue
      fi
      warn "      * Container running without CPU restrictions: $c"
      cpu_unlimited_containers="$cpu_unlimited_containers $c"
    fi
  done
  # We went through all the containers and found no lack of CPUShare restrictions
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Containers running without CPU restrictions" "$cpu_unlimited_containers"
}

check_5_12() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.12"
  local desc="确保容器的根文件系统挂载为只读（自动）"
  local remediation="您应该在容器的运行时添加一个 --read-only 标志，以强制将容器的根文件系统挂载为只读。"
  local remediationImpact="如果未定义数据写入策略，则在容器运行时启用 --read-only 可能会破坏某些容器操作系统包。您应该定义容器的数据在运行时应该和不应该保留的内容，以便决定使用哪种策略。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  fsroot_mount_containers=""
  for c in $containers; do
   read_status=$(docker inspect --format '{{ .HostConfig.ReadonlyRootfs }}' "$c")

    if [ "$read_status" = "false" ]; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "      * Container running with root FS mounted R/W: $c"
        fsroot_mount_containers="$fsroot_mount_containers $c"
        fail=1
        continue
      fi
      warn "      * Container running with root FS mounted R/W: $c"
      fsroot_mount_containers="$fsroot_mount_containers $c"
    fi
  done
  # We went through all the containers and found no R/W FS mounts
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Containers running with root FS mounted R/W" "$fsroot_mount_containers"
}

check_5_13() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.13"
  local desc="确保传入的容器流量绑定到特定的主机接口（自动）"
  local remediation="您应该将容器端口绑定到所需主机端口上的特定主机接口。示例：docker run --detach --publish 10.2.3.4:49153:80 nginx 在此示例中，容器端口 80 绑定到 49153 上的主机端口，并且仅接受来自 10.2.3.4 外部接口的传入连接。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  incoming_unbound_containers=""
  for c in $containers; do
    for ip in $(docker port "$c" | awk '{print $3}' | cut -d ':' -f1); do
      if [ "$ip" = "0.0.0.0" ]; then
        # If it's the first container, fail the test
        if [ $fail -eq 0 ]; then
          warn -s "$check"
          warn "      * Port being bound to wildcard IP: $ip in $c"
          incoming_unbound_containers="$incoming_unbound_containers $c:$ip"
          fail=1
          continue
        fi
        warn "      * Port being bound to wildcard IP: $ip in $c"
        incoming_unbound_containers="$incoming_unbound_containers $c:$ip"
      fi
    done
  done
  # We went through all the containers and found no ports bound to 0.0.0.0
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Containers with port bound to wildcard IP" "$incoming_unbound_containers"
}

check_5_14() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.14"
  local desc="确保“失败时”容器重启策略设置为“5”（自动）"
  local remediation="如果您希望容器自动重启，示例命令是 docker run --detach --restart=on-failure:5 nginx"
  local remediationImpact="如果设置了这个选项，容器只会尝试重启 5 次。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  maxretry_unset_containers=""
  for c in $containers; do
    policy=$(docker inspect --format MaximumRetryCount='{{ .HostConfig.RestartPolicy.MaximumRetryCount }}' "$c")

    if [ "$policy" != "MaximumRetryCount=5" ]; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "      * MaximumRetryCount is not set to 5: $c"
        maxretry_unset_containers="$maxretry_unset_containers $c"
        fail=1
        continue
      fi
      warn "      * MaximumRetryCount is not set to 5: $c"
      maxretry_unset_containers="$maxretry_unset_containers $c"
    fi
  done
  # We went through all the containers and they all had MaximumRetryCount=5
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Containers with MaximumRetryCount not set to 5" "$maxretry_unset_containers"
}

check_5_15() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.15"
  local desc="确保主机的进程名称空间不共享（自动）"
  local remediation="您不应该使用 --pid=host 参数启动容器。"
  local remediationImpact="容器进程看不到主机系统上的进程。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  pidns_shared_containers=""
  for c in $containers; do
    mode=$(docker inspect --format 'PidMode={{.HostConfig.PidMode }}' "$c")

    if [ "$mode" = "PidMode=host" ]; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "      * Host PID namespace being shared with: $c"
        pidns_shared_containers="$pidns_shared_containers $c"
        fail=1
        continue
      fi
      warn "      * Host PID namespace being shared with: $c"
      pidns_shared_containers="$pidns_shared_containers $c"
    fi
  done
  # We went through all the containers and found none with PidMode as host
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Containers sharing host PID namespace" "$pidns_shared_containers"
}

check_5_16() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.16"
  local desc="确保主机的 IPC 名称空间未共享（自动）"
  local remediation="您不应该使用 --ipc=host 参数启动容器。"
  local remediationImpact="共享内存段用于加速进程间通信，通常用于高性能应用程序。如果此类应用程序容器化到多个容器中，您可能需要共享容器的 IPC 命名空间以实现高性能。在这些情况下，您仍然应该只共享容器特定的 IPC 命名空间，而不是主机 IPC 命名空间。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  ipcns_shared_containers=""
  for c in $containers; do
    mode=$(docker inspect --format 'IpcMode={{.HostConfig.IpcMode }}' "$c")

    if [ "$mode" = "IpcMode=host" ]; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "      * Host IPC namespace being shared with: $c"
        ipcns_shared_containers="$ipcns_shared_containers $c"
        fail=1
        continue
      fi
      warn "      * Host IPC namespace being shared with: $c"
      ipcns_shared_containers="$ipcns_shared_containers $c"
    fi
  done
  # We went through all the containers and found none with IPCMode as host
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Containers sharing host IPC namespace" "$ipcns_shared_containers"
}

check_5_17() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.17"
  local desc="确保主机设备不直接暴露给容器（手动）"
  local remediation="您不应该直接将主机设备暴露给容器。如果您确实需要将主机设备暴露给容器，您应该使用适合您组织的精细权限。"
  local remediationImpact="您将无法直接在容器内使用主机设备。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  hostdev_exposed_containers=""
  for c in $containers; do
    devices=$(docker inspect --format 'Devices={{ .HostConfig.Devices }}' "$c")

    if [ "$devices" != "Devices=" ] && [ "$devices" != "Devices=[]" ] && [ "$devices" != "Devices=<no value>" ]; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        info -c "$check"
        info "      * Container has devices exposed directly: $c"
        hostdev_exposed_containers="$hostdev_exposed_containers $c"
        fail=1
        continue
      fi
      info "      * Container has devices exposed directly: $c"
      hostdev_exposed_containers="$hostdev_exposed_containers $c"
    fi
  done
  # We went through all the containers and found none with devices
  if [ $fail -eq 0 ]; then
    pass -c "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "INFO" "Containers with host devices exposed directly" "$hostdev_exposed_containers"
}

check_5_18() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.18"
  local desc="如果需要，确保在运行时覆盖默认的 ulimit（手动）"
  local remediation="如果在特定情况下需要，您应该只覆盖默认的 ulimit 设置。"
  local remediationImpact="如果 ulimits 设置不正确，单个容器的过度使用可能会使主机系统无法使用。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  no_ulimit_containers=""
  for c in $containers; do
    ulimits=$(docker inspect --format 'Ulimits={{ .HostConfig.Ulimits }}' "$c")

    if [ "$ulimits" = "Ulimits=" ] || [ "$ulimits" = "Ulimits=[]" ] || [ "$ulimits" = "Ulimits=<no value>" ]; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        info -c "$check"
        info "      * Container no default ulimit override: $c"
        no_ulimit_containers="$no_ulimit_containers $c"
        fail=1
        continue
      fi
      info "      * Container no default ulimit override: $c"
      no_ulimit_containers="$no_ulimit_containers $c"
    fi
  done
  # We went through all the containers and found none without Ulimits
  if [ $fail -eq 0 ]; then
    pass -c "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "INFO" "Containers with no default ulimit override" "$no_ulimit_containers"
}

check_5_19() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.19"
  local desc="确保安装传播模式未设置为共享（自动）"
  local remediation="不要在共享模式传播中安装卷。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  mountprop_shared_containers=""
  for c in $containers; do
    if docker inspect --format 'Propagation={{range $mnt := .Mounts}} {{json $mnt.Propagation}} {{end}}' "$c" | \
     grep shared 2>/dev/null 1>&2; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "      * Mount propagation mode is shared: $c"
        mountprop_shared_containers="$mountprop_shared_containers $c"
        fail=1
        continue
      fi
      warn "      * Mount propagation mode is shared: $c"
      mountprop_shared_containers="$mountprop_shared_containers $c"
    fi
  done
  # We went through all the containers and found none with shared propagation mode
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Containers with shared mount propagation" "$mountprop_shared_containers"
}

check_5_20() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.20"
  local desc="确保主机的 UTS 名称空间未共享（自动）"
  local remediation="您不应使用 --uts=host 参数启动容器。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  utcns_shared_containers=""
  for c in $containers; do
    mode=$(docker inspect --format 'UTSMode={{.HostConfig.UTSMode }}' "$c")

    if [ "$mode" = "UTSMode=host" ]; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "      * Host UTS namespace being shared with: $c"
        utcns_shared_containers="$utcns_shared_containers $c"
        fail=1
        continue
      fi
      warn "      * Host UTS namespace being shared with: $c"
      utcns_shared_containers="$utcns_shared_containers $c"
    fi
  done
  # We went through all the containers and found none with UTSMode as host
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Containers sharing host UTS namespace" "$utcns_shared_containers"
}

check_5_21() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.21"
  local desc="确保默认的 seccomp 配置文件未禁用（自动）"
  local remediation="默认情况下，启用 seccomp 配置文件。除非您想修改和使用修改后的 seccomp 配置文件，否则您不需要执行任何操作。"
  local remediationImpact="对于 Docker 1.10 及更高版本，默认的 seccomp 配置文件会阻止系统调用，无论传递给容器的 --cap-add 是什么。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  seccomp_disabled_containers=""
  for c in $containers; do
    if docker inspect --format 'SecurityOpt={{.HostConfig.SecurityOpt }}' "$c" | \
      grep -E 'seccomp:unconfined|seccomp=unconfined' 2>/dev/null 1>&2; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "      * Default seccomp profile disabled: $c"
        seccomp_disabled_containers="$seccomp_disabled_containers $c"
        fail=1
      else
        warn "      * Default seccomp profile disabled: $c"
        seccomp_disabled_containers="$seccomp_disabled_containers $c"
      fi
    fi
  done
  # We went through all the containers and found none with default secomp profile disabled
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Containers with default seccomp profile disabled" "$seccomp_disabled_containers"
}

check_5_22() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.22"
  local desc="确保 docker exec 命令不与特权选项一起使用（自动）"
  local remediation="您不应在 docker exec 命令中使用 --privileged 选项。"
  local remediationImpact="如果您需要容器内的增强功能，请使用它所需的所有权限运行它。这些应该单独指定。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "NOTE"
}

check_5_23() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.23"
  local desc="确保 docker exec 命令不与 user=root 选项一起使用（手动）"
  local remediation="您不应在 docker exec 命令中使用 --user=root 选项。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  note -c "$check"
  logcheckresult "NOTE"
}

check_5_24() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.24"
  local desc="确保确认 cgroup 的使用（自动）"
  local remediation="除非严格要求，否则不应在 docker run 命令中使用 --cgroup-parent 选项。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  unexpected_cgroup_containers=""
  for c in $containers; do
    mode=$(docker inspect --format 'CgroupParent={{.HostConfig.CgroupParent }}x' "$c")

    if [ "$mode" != "CgroupParent=x" ]; then
      # If it's the first container, fail the test
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "      * Confirm cgroup usage: $c"
        unexpected_cgroup_containers="$unexpected_cgroup_containers $c"
        fail=1
        continue
      fi
      warn "      * Confirm cgroup usage: $c"
      unexpected_cgroup_containers="$unexpected_cgroup_containers $c"
    fi
  done
  # We went through all the containers and found none with UTSMode as host
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
    logcheckresult "WARN" "Containers using unexpected cgroup" "$unexpected_cgroup_containers"
}

check_5_25() {
  if [ -z "$containers" ]; then
    return
  fi
  local id="5.25"
  local desc="确保容器被限制获取额外的权限（自动）"
  local remediation="您应该使用以下选项启动您的容器： docker run --rm -it --security-opt=no-new-privileges ubuntu bash"
  local remediationImpact="no_new_priv 选项阻止像 SELinux 这样的 LSM 允许进程获得新的权限。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  no_priv_config=0
  addprivs_containers=""

  if get_docker_effective_command_line_args '--no-new-privileges' | grep "no-new-privileges" >/dev/null 2>&1; then
    no_priv_config=1
  elif get_docker_configuration_file_args 'no-new-privileges' | grep true >/dev/null 2>&1; then
    no_priv_config=1
  else
    for c in $containers; do
      if ! docker inspect --format 'SecurityOpt={{.HostConfig.SecurityOpt }}' "$c" | grep 'no-new-privileges' 2>/dev/null 1>&2; then
        # If it's the first container, fail the test
        if [ $fail -eq 0 ]; then
          warn -s "$check"
          warn "      * Privileges not restricted: $c"
          addprivs_containers="$addprivs_containers $c"
          fail=1
          continue
        fi
        warn "      * Privileges not restricted: $c"
        addprivs_containers="$addprivs_containers $c"
      fi
    done
  fi

  # We went through all the containers and found none with capability to acquire additional privileges
  if [ $fail -eq 0 ] || [ $no_priv_config -eq 1 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Containers without restricted privileges" "$addprivs_containers"
}

check_5_26() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.26"
  local desc="确保在运行时检查容器健康状况（自动）"
  local remediation="您应该使用 --health-cmd 参数运行容器。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  nohealthcheck_containers=""
  for c in $containers; do
    if ! docker inspect --format '{{ .Id }}: Health={{ .State.Health.Status }}' "$c" 2>/dev/null 1>&2; then
      if [ $fail -eq 0 ]; then
        warn -s "$check"
        warn "      * Health check not set: $c"
        nohealthcheck_containers="$nohealthcheck_containers $c"
        fail=1
        continue
      fi
      warn "      * Health check not set: $c"
      nohealthcheck_containers="$nohealthcheck_containers $c"
    fi
  done
  if [ $fail -eq 0 ]; then
    pass -s "$check"
    logcheckresult "PASS"
    return
  fi
  logcheckresult "WARN" "Containers without health check" "$nohealthcheck_containers"
}

check_5_27() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.27"
  local desc="确保 Docker 命令始终使用最新版本的镜像（手动）"
  local remediation="您应该使用适当的版本固定机制（默认分配的 <latest> 标记仍然容易受到缓存攻击）以避免提取缓存的旧版本。版本锁定机制应该用于基础镜像、包和整个镜像。您可以根据需要自定义版本固定规则。"
  local remediationImpact="None."
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  info -c "$check"
  logcheckresult "INFO"
}

check_5_28() {
  if [ -z "$containers" ]; then
    return
  fi

  local id="5.28"
  local desc="确保使用 PID cgroup 限制（自动）"
  local remediation="启动容器时使用具有适当值的 --pids-limit 标志。"
  local remediationImpact="适当设置 PID 限制值。不正确的值可能会使容器无法使用。"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  fail=0
  nopids_limit_containers=""
  for c in $containers; do
    pidslimit="$(docke