info "5 - Policies"
info "5.1 - RBAC and Service Accounts"

# Make the loop separator be a new-line in POSIX compliant fashion
set -f; IFS=$'
'

check_5_1_1="5.1.1  - Ensure that the cluster-admin role is only used where required (Manual)"
cluster_admins=$(kubectl get clusterrolebindings -o=custom-columns=NAME:.metadata.name,ROLE:.roleRef.name,SUBJECT:.subjects[*].name)
info "$check_5_1_1"
for admin in $cluster_admins; do
 	info "     * $admin"
done

check_5_1_2="5.1.2  - Minimize access to secrets (Manual)"
policies=$(kubectl get psp)
info "$check_5_1_2"
for policy in $policies; do
	  info "     * $policy"
done

check_5_1_3="5.1.3  - Create administrative boundaries between resources using namespaces (Manual)"
namespaces=$(kubectl get namespaces)
info "$check_5_1_3"
for namespace in $namespaces; do
	info "     * $namespace"
done

check_5_1_4="5.1.4  - Create network segmentation using Network Policies (Manual)"
policies=$(kubectl get pods --namespace=kube-system)
info "$check_5_1_4"
for policy in $policies; do
	info "     * $policy"
done

check_5_1_5="5.1.5  - Avoid using Kubernetes Secrets (Manual)"
secrets=$(kubectl get secrets)
info "$check_5_1_5"
for secret in $secrets; do
	info "     * $secret"
done

#TODO
check_5_1_6="5.1.6  - Ensure that Service Account Tokens are only mounted where necessary (Manual)"
info "$check_5_1_6"
check_5_1_7="5.1.7  - Avoid use of system:masters group (Manual)"
info "$check_5_1_7"
check_5_1_8="5.1.8  - Limit use of the Bind, Impersonate and Escalate permissions in the Kubernetes cluster (Manual)"
info "$check_5_1_8"
check_5_1_9="5.1.9  - Minimize access to create persistent volumes (Manual)"
info "$check_5_1_9"
check_5_1_9="5.1.10  - Minimize access to the proxy sub-resource of nodes (Manual)"
info "$check_5_1_10"
check_5_1_9="5.1.11  - Minimize access to the approval sub-resource of certificatesigningrequests objects (Manual)"
info "$check_5_1_11"
check_5_1_9="5.1.12  - Minimize access to webhook configuration objects (Manual)"
info "$check_5_1_12"
check_5_1_9="5.1.13  - Minimize access to the service account token creation (Manual)"
info "$check_5_1_13"


info "5.2 - Pod Security Policies"

check_5_2_1="5.2.1  - Minimize the admission of privileged containers (Manual)"
info "$check_5_2_1"
check_5_2_2="5.2.2  - Minimize the admission of containers wishing to share the host process ID namespace (Manual)"
info "$check_5_2_2"
check_5_2_3="5.2.3  - Minimize the admission of containers wishing to share the host IPC namespace (Manual)"
info "$check_5_2_3"
check_5_2_4="5.2.4  - Minimize the admission of containers wishing to share the host network namespace (Manual)"
info "$check_5_2_4"
check_5_2_5="5.2.5  - Minimize the admission of containers with allowPrivilegeEscalation (Manual)"
info "$check_5_2_5"
check_5_2_6="5.2.6  - Minimize the admission of root containers (Manual)"
info "$check_5_2_6"
check_5_2_7="5.2.7  - Minimize the admission of containers with the NET_RAW capability (Manual)"
info "$check_5_2_7"
check_5_2_8="5.2.8  - Minimize the admission of containers with added capabilities (Manual)"
info "$check_5_2_8"
check_5_2_9="5.2.9  - Minimize the admission of containers with capabilities assigned (Manual)"
info "$check_5_2_9"

check_5_2_9="5.2.10  - Minimize the admission of containers with capabilities assigned (Manual)"
info "$check_5_2_10"
check_5_2_9="5.2.11  - Minimize the admission of Windows HostProcess Containers (Manual)"
info "$check_5_2_11"
check_5_2_9="5.2.12  - Minimize the admission of HostPath volumes (Manual)"
info "$check_5_2_12"
check_5_2_9="5.2.13  - Minimize the admission of containers which use HostPorts (Manual)"
info "$check_5_2_13"

info "5.3 - Network Policies and CNI"
check_5_3_1="5.3.1  - Ensure that the CNI in use supports Network Policies (Manual)"
info "$check_5_3_1"
check_5_3_2="5.3.2  - Ensure that all Namespaces have Network Policies defined (Manual)"
info "$check_5_3_2"

info "5.4 - Secrets Management"
check_5_4_1="5.4.1  - Prefer using secrets as files over secrets as environment variables (Manual)"
info "$check_5_4_1"
check_5_4_2="5.4.2  - Consider external secret storage (Manual)"
info "$check_5_4_2"

info "5.5 - Extensible Admission Control"
check_5_5_1="5.5.1  - Configure Image Provenance using ImagePolicyWebhook admission controller (Manual)"
info "$check_5_5_1"

info "5.7 - General Policies"
check_5_7_1="5.7.1  - Create administrative boundaries between resources using namespaces (Manual)"
info "$check_5_7_1"
#todo remedition
check_5_7_2="5.7.2  - Ensure that the seccomp profile is set to docker/default in your pod definitions (Manual)"
info "$check_5_7_2"
check_5_7_3="5.7.3  - Apply Security Context to Your Pods and Containers (Manual)"
info "$check_5_6_3"
check_5_7_4="5.7.4  - The default namespace should not be used (Manual)"
info "$check_5_7_4"
