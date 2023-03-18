# azurerm-aks


terraform-azurerm-aks
Deploys a Kubernetes cluster on AKS with monitoring support through Azure Log Analytics

This Terraform module deploys a Kubernetes cluster on Azure using AKS (Azure Kubernetes Service) and adds support for monitoring with Log Analytics.

-> NOTE: If you have not assigned client_id or client_secret, A SystemAssigned identity will be created.
Notice on Upgrade to V6.x

We've added a CI pipeline for this module to speed up our code review and to enforce a high code quality standard, if you want to contribute by submitting a pull request, please read Pre-Commit & Pr-Check & Test section, or your pull request might be rejected by CI pipeline.

A pull request will be reviewed when it has passed Pre Pull Request Check in the pipeline, and will be merged when it has passed the acceptance tests. Once the ci Pipeline failed, please read the pipeline's output, thanks for your cooperation.
Notice on Upgrade to V5.x

V5.0.0 is a major version upgrade and a lot of breaking changes have been introduced. Extreme caution must be taken during the upgrade to avoid resource replacement and downtime by accident.

Running the terraform plan first to inspect the plan is strongly advised.
Terraform and terraform-provider-azurerm version restrictions

Now Terraform core's lowest version is v1.2.0 and terraform-provider-azurerm's lowest version is v3.21.0.
variable user_assigned_identity_id has been renamed.

variable user_assigned_identity_id has been renamed to identity_ids and it's type has been changed from string to list(string).
addon_profile in outputs is no longer available.

It has been broken into the following new outputs:

    aci_connector_linux
    aci_connector_linux_enabled
    azure_policy_enabled
    http_application_routing_enabled
    ingress_application_gateway
    ingress_application_gateway_enabled
    key_vault_secrets_provider
    key_vault_secrets_provider_enabled
    oms_agent
    oms_agent_enabled
    open_service_mesh_enabled

The following variables have been renamed from enable_xxx to xxx_enabled

    enable_azure_policy has been renamed to azure_policy_enabled
    enable_http_application_routing has been renamed to http_application_routing_enabled
    enable_ingress_application_gateway has been renamed to ingress_application_gateway_enabled
    enable_log_analytics_workspace has been renamed to log_analytics_workspace_enabled
    enable_open_service_mesh has been renamed to open_service_mesh_enabled
    enable_role_based_access_control has been renamed to role_based_access_control_enabled

nullable = true has been added to the following variables so setting them to null explicitly will use the default value

    log_analytics_workspace_enable
    os_disk_type
    private_cluster_enabled
    rbac_aad_managed
    rbac_aad_admin_group_object_ids
    network_policy
    enable_node_public_ip

var.admin_username's default value has been removed

In v4.x var.admin_username has a default value azureuser and has been removed in V5.0.0. Since the admin_username argument in linux_profile block is a ForceNew argument, any value change to this argument will trigger a Kubernetes cluster replacement SO THE EXTREME CAUTION MUST BE TAKEN. The module's callers must set var.admin_username to azureuser explicitly if they didn't set it before.
module.ssh-key has been removed

The file named private_ssh_key which contains the tls private key will be deleted since the local_file resource has been removed. Now the private key is exported via generated_cluster_private_ssh_key in output and the corresponding public key is exported via generated_cluster_public_ssh_key in output.

A moved block has been added to relocate the existing tls_private_key resource to the new address. If the var.admin_username is not null, no action is needed.

Resource tls_private_key's creation now is conditional. Users may see the destruction of existing tls_private_key in the generated plan if var.admin_username is null.
system_assigned_identity in the output has been renamed to cluster_identity

The system_assigned_identity was:

output "system_assigned_identity" {
  value = azurerm_kubernetes_cluster.main.identity
}

Now it has been renamed to cluster_identity, and the block has been changed to:

output "cluster_identity" {
  description = "The `azurerm_kubernetes_cluster`'s `identity` block."
  value       = try(azurerm_kubernetes_cluster.main.identity[0], null)
}

The callers who used to read the cluster's identity block need to remove the index in their expression, from module.aks.system_assigned_identity[0] to module.aks.cluster_identity.
The following outputs are now sensitive. All outputs referenced them must be declared as sensitive too

    client_certificate
    client_key
    cluster_ca_certificate
    generated_cluster_private_ssh_key
    host
    kube_admin_config_raw
    kube_config_raw
    password
    username

Usage in Terraform 1.2.0

Please view folders in examples.

The module supports some outputs that may be used to configure a kubernetes provider after deploying an AKS cluster.

provider "kubernetes" {
  host                   = module.aks.host
  client_certificate     = base64decode(module.aks.client_certificate)
  client_key             = base64decode(module.aks.client_key)
  cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
}

There're some examples in the examples folder. You can execute terraform apply command in examples's sub folder to try the module. These examples are tested against every PR with the E2E Test.
Pre-Commit & Pr-Check & Test
Configurations

    Configure Terraform for Azure

We assumed that you have setup service principal's credentials in your environment variables like below:

export ARM_SUBSCRIPTION_ID="<azure_subscription_id>"
export ARM_TENANT_ID="<azure_subscription_tenant_id>"
export ARM_CLIENT_ID="<service_principal_appid>"
export ARM_CLIENT_SECRET="<service_principal_password>"

On Windows Powershell:

$env:ARM_SUBSCRIPTION_ID="<azure_subscription_id>"
$env:ARM_TENANT_ID="<azure_subscription_tenant_id>"
$env:ARM_CLIENT_ID="<service_principal_appid>"
$env:ARM_CLIENT_SECRET="<service_principal_password>"

We provide a docker image to run the pre-commit checks and tests for you: mcr.microsoft.com/azterraform:latest

To run the pre-commit task, we can run the following command:

$ docker run --rm -v $(pwd):/src -w /src mcr.microsoft.com/azterraform:latest make pre-commit

On Windows Powershell:

$ docker run --rm -v ${pwd}:/src -w /src mcr.microsoft.com/azterraform:latest make pre-commit

In pre-commit task, we will:

    Run terraform fmt -recursive command for your Terraform code.
    Run terrafmt fmt -f command for markdown files and go code files to ensure that the Terraform code embedded in these files are well formatted.
    Run go mod tidy and go mod vendor for test folder to ensure that all the dependencies have been synced.
    Run gofmt for all go code files.
    Run gofumpt for all go code files.
    Run terraform-docs on README.md file, then run markdown-table-formatter to format markdown tables in README.md.

Then we can run the pr-check task to check whether our code meets our pipeline's requirement(We strongly recommend you run the following command before you commit):

$ docker run --rm -v $(pwd):/src -w /src mcr.microsoft.com/azterraform:latest make pr-check

On Windows Powershell:

$ docker run --rm -v ${pwd}:/src -w /src mcr.microsoft.com/azterraform:latest make pr-check

To run the e2e-test, we can run the following command:

docker run --rm -v $(pwd):/src -w /src -e ARM_SUBSCRIPTION_ID -e ARM_TENANT_ID -e ARM_CLIENT_ID -e ARM_CLIENT_SECRET mcr.microsoft.com/azterraform:latest make e2e-test

On Windows Powershell:

docker run --rm -v ${pwd}:/src -w /src -e ARM_SUBSCRIPTION_ID -e ARM_TENANT_ID -e ARM_CLIENT_ID -e ARM_CLIENT_SECRET mcr.microsoft.com/azterraform:latest make e2e-test

To follow Ensure AKS uses disk encryption set policy we've used azurerm_key_vault in example codes, and to follow Key vault does not allow firewall rules settings we've limited the ip cidr on it's network_acls. On default we'll use the ip return by https://api.ipify.org?format=json api as your public ip, but in case you need use other cidr, you can assign on by passing an environment variable:

docker run --rm -v $(pwd):/src -w /src -e TF_VAR_key_vault_firewall_bypass_ip_cidr="<your_cidr>" -e ARM_SUBSCRIPTION_ID -e ARM_TENANT_ID -e ARM_CLIENT_ID -e ARM_CLIENT_SECRET mcr.microsoft.com/azterraform:latest make e2e-test

On Windows Powershell:

docker run --rm -v ${pwd}:/src -w /src -e TF_VAR_key_vault_firewall_bypass_ip_cidr="<your_cidr>" -e ARM_SUBSCRIPTION_ID -e ARM_TENANT_ID -e ARM_CLIENT_ID -e ARM_CLIENT_SECRET mcr.microsoft.com/azterraform:latest make e2e-test

Prerequisites

    Docker

Authors

Originally created by Damien Caro and Malte Lantin
License

MIT
Contributing

This project welcomes contributions and suggestions. Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the Microsoft Open Source Code of Conduct. For more information see the Code of Conduct FAQ or contact opencode@microsoft.com with any additional questions or comments.
Module Spec

The following sections are generated by terraform-docs and markdown-table-formatter, please DO NOT MODIFY THEM MANUALLY!
Requirements
Name 	Version
terraform 	>= 1.2
azurerm 	>= 3.40, < 4.0
tls 	>= 3.1
Providers
Name 	Version
azurerm 	>= 3.40, < 4.0
tls 	>= 3.1
Modules

No modules.
Resources
Name 	Type
azurerm_kubernetes_cluster.main 	resource
azurerm_kubernetes_cluster_node_pool.node_pool 	resource
azurerm_log_analytics_solution.main 	resource
azurerm_log_analytics_workspace.main 	resource
azurerm_role_assignment.acr 	resource
tls_private_key.ssh 	resource
azurerm_resource_group.main 	data source
Inputs
Name 	Description 	Type 	Default 	Required
aci_connector_linux_enabled 	Enable Virtual Node pool 	bool 	false 	no
aci_connector_linux_subnet_name 	(Optional) aci_connector_linux subnet name 	string 	null 	no
admin_username 	The username of the local administrator to be created on the Kubernetes cluster. Set this variable to null to turn off the cluster's linux_profile. Changing this forces a new resource to be created. 	string 	null 	no
agents_availability_zones 	(Optional) A list of Availability Zones across which the Node Pool should be spread. Changing this forces a new resource to be created. 	list(string) 	null 	no
agents_count 	The number of Agents that should exist in the Agent Pool. Please set agents_count null while enable_auto_scaling is true to avoid possible agents_count changes. 	number 	2 	no
agents_labels 	(Optional) A map of Kubernetes labels which should be applied to nodes in the Default Node Pool. Changing this forces a new resource to be created. 	map(string) 	{} 	no
agents_max_count 	Maximum number of nodes in a pool 	number 	null 	no
agents_max_pods 	(Optional) The maximum number of pods that can run on each agent. Changing this forces a new resource to be created. 	number 	null 	no
agents_min_count 	Minimum number of nodes in a pool 	number 	null 	no
agents_pool_kubelet_configs 	list(object({
cpu_manager_policy = (Optional) Specifies the CPU Manager policy to use. Possible values are none and static, Changing this forces a new resource to be created.
cpu_cfs_quota_enabled = (Optional) Is CPU CFS quota enforcement for containers enabled? Changing this forces a new resource to be created.
cpu_cfs_quota_period = (Optional) Specifies the CPU CFS quota period value. Changing this forces a new resource to be created.
image_gc_high_threshold = (Optional) Specifies the percent of disk usage above which image garbage collection is always run. Must be between 0 and 100. Changing this forces a new resource to be created.
image_gc_low_threshold = (Optional) Specifies the percent of disk usage lower than which image garbage collection is never run. Must be between 0 and 100. Changing this forces a new resource to be created.
topology_manager_policy = (Optional) Specifies the Topology Manager policy to use. Possible values are none, best-effort, restricted or single-numa-node. Changing this forces a new resource to be created.
allowed_unsafe_sysctls = (Optional) Specifies the allow list of unsafe sysctls command or patterns (ending in *). Changing this forces a new resource to be created.
container_log_max_size_mb = (Optional) Specifies the maximum size (e.g. 10MB) of container log file before it is rotated. Changing this forces a new resource to be created.
container_log_max_line = (Optional) Specifies the maximum number of container log files that can be present for a container. must be at least 2. Changing this forces a new resource to be created.
pod_max_pid = (Optional) Specifies the maximum number of processes per pod. Changing this forces a new resource to be created.
})) 	

list(object({
    cpu_manager_policy        = optional(string)
    cpu_cfs_quota_enabled     = optional(bool, true)
    cpu_cfs_quota_period      = optional(string)
    image_gc_high_threshold   = optional(number)
    image_gc_low_threshold    = optional(number)
    topology_manager_policy   = optional(string)
    allowed_unsafe_sysctls    = optional(set(string))
    container_log_max_size_mb = optional(number)
    container_log_max_line    = optional(number)
    pod_max_pid               = optional(number)
  }))

	[] 	no
agents_pool_linux_os_configs 	list(object({
sysctl_configs = optional(list(object({
fs_aio_max_nr = (Optional) The sysctl setting fs.aio-max-nr. Must be between 65536 and 6553500. Changing this forces a new resource to be created.
fs_file_max = (Optional) The sysctl setting fs.file-max. Must be between 8192 and 12000500. Changing this forces a new resource to be created.
fs_inotify_max_user_watches = (Optional) The sysctl setting fs.inotify.max_user_watches. Must be between 781250 and 2097152. Changing this forces a new resource to be created.
fs_nr_open = (Optional) The sysctl setting fs.nr_open. Must be between 8192 and 20000500. Changing this forces a new resource to be created.
kernel_threads_max = (Optional) The sysctl setting kernel.threads-max. Must be between 20 and 513785. Changing this forces a new resource to be created.
net_core_netdev_max_backlog = (Optional) The sysctl setting net.core.netdev_max_backlog. Must be between 1000 and 3240000. Changing this forces a new resource to be created.
net_core_optmem_max = (Optional) The sysctl setting net.core.optmem_max. Must be between 20480 and 4194304. Changing this forces a new resource to be created.
net_core_rmem_default = (Optional) The sysctl setting net.core.rmem_default. Must be between 212992 and 134217728. Changing this forces a new resource to be created.
net_core_rmem_max = (Optional) The sysctl setting net.core.rmem_max. Must be between 212992 and 134217728. Changing this forces a new resource to be created.
net_core_somaxconn = (Optional) The sysctl setting net.core.somaxconn. Must be between 4096 and 3240000. Changing this forces a new resource to be created.
net_core_wmem_default = (Optional) The sysctl setting net.core.wmem_default. Must be between 212992 and 134217728. Changing this forces a new resource to be created.
net_core_wmem_max = (Optional) The sysctl setting net.core.wmem_max. Must be between 212992 and 134217728. Changing this forces a new resource to be created.
net_ipv4_ip_local_port_range_min = (Optional) The sysctl setting net.ipv4.ip_local_port_range max value. Must be between 1024 and 60999. Changing this forces a new resource to be created.
net_ipv4_ip_local_port_range_max = (Optional) The sysctl setting net.ipv4.ip_local_port_range min value. Must be between 1024 and 60999. Changing this forces a new resource to be created.
net_ipv4_neigh_default_gc_thresh1 = (Optional) The sysctl setting net.ipv4.neigh.default.gc_thresh1. Must be between 128 and 80000. Changing this forces a new resource to be created.
net_ipv4_neigh_default_gc_thresh2 = (Optional) The sysctl setting net.ipv4.neigh.default.gc_thresh2. Must be between 512 and 90000. Changing this forces a new resource to be created.
net_ipv4_neigh_default_gc_thresh3 = (Optional) The sysctl setting net.ipv4.neigh.default.gc_thresh3. Must be between 1024 and 100000. Changing this forces a new resource to be created.
net_ipv4_tcp_fin_timeout = (Optional) The sysctl setting net.ipv4.tcp_fin_timeout. Must be between 5 and 120. Changing this forces a new resource to be created.
net_ipv4_tcp_keepalive_intvl = (Optional) The sysctl setting net.ipv4.tcp_keepalive_intvl. Must be between 10 and 75. Changing this forces a new resource to be created.
net_ipv4_tcp_keepalive_probes = (Optional) The sysctl setting net.ipv4.tcp_keepalive_probes. Must be between 1 and 15. Changing this forces a new resource to be created.
net_ipv4_tcp_keepalive_time = (Optional) The sysctl setting net.ipv4.tcp_keepalive_time. Must be between 30 and 432000. Changing this forces a new resource to be created.
net_ipv4_tcp_max_syn_backlog = (Optional) The sysctl setting net.ipv4.tcp_max_syn_backlog. Must be between 128 and 3240000. Changing this forces a new resource to be created.
net_ipv4_tcp_max_tw_buckets = (Optional) The sysctl setting net.ipv4.tcp_max_tw_buckets. Must be between 8000 and 1440000. Changing this forces a new resource to be created.
net_ipv4_tcp_tw_reuse = (Optional) The sysctl setting net.ipv4.tcp_tw_reuse. Changing this forces a new resource to be created.
net_netfilter_nf_conntrack_buckets = (Optional) The sysctl setting net.netfilter.nf_conntrack_buckets. Must be between 65536 and 147456. Changing this forces a new resource to be created.
net_netfilter_nf_conntrack_max = (Optional) The sysctl setting net.netfilter.nf_conntrack_max. Must be between 131072 and 1048576. Changing this forces a new resource to be created.
vm_max_map_count = (Optional) The sysctl setting vm.max_map_count. Must be between 65530 and 262144. Changing this forces a new resource to be created.
vm_swappiness = (Optional) The sysctl setting vm.swappiness. Must be between 0 and 100. Changing this forces a new resource to be created.
vm_vfs_cache_pressure = (Optional) The sysctl setting vm.vfs_cache_pressure. Must be between 0 and 100. Changing this forces a new resource to be created.
})), [])
transparent_huge_page_enabled = (Optional) Specifies the Transparent Huge Page enabled configuration. Possible values are always, madvise and never. Changing this forces a new resource to be created.
transparent_huge_page_defrag = (Optional) specifies the defrag configuration for Transparent Huge Page. Possible values are always, defer, defer+madvise, madvise and never. Changing this forces a new resource to be created.
swap_file_size_mb = (Optional) Specifies the size of the swap file on each node in MB. Changing this forces a new resource to be created.
})) 	

list(object({
    sysctl_configs = optional(list(object({
      fs_aio_max_nr                      = optional(number)
      fs_file_max                        = optional(number)
      fs_inotify_max_user_watches        = optional(number)
      fs_nr_open                         = optional(number)
      kernel_threads_max                 = optional(number)
      net_core_netdev_max_backlog        = optional(number)
      net_core_optmem_max                = optional(number)
      net_core_rmem_default              = optional(number)
      net_core_rmem_max                  = optional(number)
      net_core_somaxconn                 = optional(number)
      net_core_wmem_default              = optional(number)
      net_core_wmem_max                  = optional(number)
      net_ipv4_ip_local_port_range_min   = optional(number)
      net_ipv4_ip_local_port_range_max   = optional(number)
      net_ipv4_neigh_default_gc_thresh1  = optional(number)
      net_ipv4_neigh_default_gc_thresh2  = optional(number)
      net_ipv4_neigh_default_gc_thresh3  = optional(number)
      net_ipv4_tcp_fin_timeout           = optional(number)
      net_ipv4_tcp_keepalive_intvl       = optional(number)
      net_ipv4_tcp_keepalive_probes      = optional(number)
      net_ipv4_tcp_keepalive_time        = optional(number)
      net_ipv4_tcp_max_syn_backlog       = optional(number)
      net_ipv4_tcp_max_tw_buckets        = optional(number)
      net_ipv4_tcp_tw_reuse              = optional(bool)
      net_netfilter_nf_conntrack_buckets = optional(number)
      net_netfilter_nf_conntrack_max     = optional(number)
      vm_max_map_count                   = optional(number)
      vm_swappiness                      = optional(number)
      vm_vfs_cache_pressure              = optional(number)
    })), [])
    transparent_huge_page_enabled = optional(string)
    transparent_huge_page_defrag  = optional(string)
    swap_file_size_mb             = optional(number)
  }))

	[] 	no
agents_pool_name 	The default Azure AKS agentpool (nodepool) name. 	string 	"nodepool" 	no
agents_size 	The default virtual machine size for the Kubernetes agents 	string 	"Standard_D2s_v3" 	no
agents_tags 	(Optional) A mapping of tags to assign to the Node Pool. 	map(string) 	{} 	no
agents_taints 	(Optional) A list of the taints added to new nodes during node pool create and scale. Changing this forces a new resource to be created. 	list(string) 	null 	no
agents_type 	(Optional) The type of Node Pool which should be created. Possible values are AvailabilitySet and VirtualMachineScaleSets. Defaults to VirtualMachineScaleSets. 	string 	"VirtualMachineScaleSets" 	no
api_server_authorized_ip_ranges 	(Optional) The IP ranges to allow for incoming traffic to the server nodes. 	set(string) 	null 	no
attached_acr_id_map 	Azure Container Registry ids that need an authentication mechanism with Azure Kubernetes Service (AKS). Map key must be static string as acr's name, the value is acr's resource id. Changing this forces some new resources to be created. 	map(string) 	{} 	no
auto_scaler_profile_balance_similar_node_groups 	Detect similar node groups and balance the number of nodes between them. Defaults to false. 	bool 	false 	no
auto_scaler_profile_empty_bulk_delete_max 	Maximum number of empty nodes that can be deleted at the same time. Defaults to 10. 			
About
