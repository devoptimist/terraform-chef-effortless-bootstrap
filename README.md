# Overview
This module will use a chef `Effortless Infra` package to bootstrap a system. The name of the effortless package to run can be passed in as a variable.

#### Supported platform families:
 * Debian
 * SLES
 * RHEL
 * Windows

## Usage

```hcl

module "chef_habitat_install" {
  source               = "srb3/effortless-bootstrap/chef"
  version              = "0.0.16"
  ips                  = ["172.16.0.23"]
  instance_count       = 1
  ssh_user_name        = "ec2-user"
  ssh_user_private_key = "~/.ssh/id_rsa"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
|ips|A list of ip addresses where the effortless package and habitat will be installed|list|[]|no|
|instance_count|The number of instances being created|number|0|no|
|user_name|The ssh or winrm user name used to access the ip addresses provided|string|""|no|
|user_pass|The ssh or winrm user password used to access the ip addresses (either user_pass/es or user_private_key/s needs to be set)|string|""|no|
|user_private_key|The ssh user key used to access the ip addresses provided (either user_pass/es or user_private_key/s needs to be set)|string|""|no|
|user_names|A list of ssh or winrm user names used to access the ip addresses provided|list|[]|no|
|user_passes|A list of ssh or winrm user passwords used to access the ip addresses (either user_pass/es or suser_private_key/s needs to be set)|list|[]|no|
|user_private_keys|A list of ssh keys used to access the ip addresses (either user_pass/es or user_private_key/s needs to be set)|list|[]|no|
|system_type|The system type linux or windows|string|linux|no|
|linux_tmp_path|The location of a temp directory to store install scripts on|string|/var/tmp|no|
|windows_tmp_path|The location of a temp directory to store install scripts on|string|$env:TEMP|no|
|windows_installer_name|The name of the windows chef install script|string|hab_installer.ps1|no|
|linux_installer_name|The name of the linux chef install script|string|hab_installer.sh|no|
|jq_windows_url|A url to a jq binary to download, used in the install process|string|https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe|no|
|jq_linux_url|A url to a jq binary to download, used in the install process|string|https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64|no|
|hab_version|The version of habitat to install|string|0.83.0|no|
|hab_linux_install_url|A url to a hab binary to download|string|https://raw.githubusercontent.com/habitat-sh/habitat/master/components/hab/install.sh|no|
|hab_windows_install_url|A url to a hab binary to download|string|https://api.bintray.com|no|
|effortless_pkg|The effortless package used to bootstrap with|string||yes|
|clear_node_data|Should the node data be cleared after the effortless chef run|bool|false|no|
|config|A list of of maps containing attributes for the effortless package. Converted to json and passed to the effortless run via a -j flag|list|[]|no|
|config_extra|A list of of maps containing attributes for the effortless package. Just before the effortless run this config is merged with the var.config data. The difference is changes in this variable will not trigger the resource to run|list|[]|no|
|hook_data|This variable is set if we need to enfroce the order in which this module is run. Use a string output of another module as the value for hook_data to ensure this module runs in order  |string|""|no|

## Outputs

| Name | Description | Type |
|------|-------------|------|
|module_hook|A list of random string outputs from each connection this module made. Used to enforce the order in which the module is run|list|
