locals {
  instance_count  = var.instance_count # length(var.ips)
  dna             = var.config
  dna_extra       = var.config_extra
  cmd             = var.system_type == "linux" ? "bash" : "powershell.exe"
  mkdir           = var.system_type == "linux" ? "mkdir -p" : "New-Item -ItemType Directory -Force -Path"
  tmp_dir_name    = split("/", var.effortless_pkg)[1]
  tmp_path        = var.system_type == "linux" ? "${var.linux_tmp_path}/${local.tmp_dir_name}" : "${var.windows_tmp_path}\\${local.tmp_dir_name}"
  installer_name  = var.system_type == "linux" ? var.linux_installer_name : var.windows_installer_name
  installer_cmd   = var.system_type == "linux" ? "${local.tmp_path}/${var.linux_installer_name}" : "Invoke-Expression ${local.tmp_path}/${var.windows_installer_name} > ${local.tmp_path}/hab_installer.log 2>&1"
  hab_install_url = var.system_type == "linux" ? var.hab_linux_install_url : var.hab_windows_install_url
  installer       = templatefile("${path.module}/templates/installer", {
    system          = var.system_type,
    hab_version     = var.hab_version,
    hab_install_url = local.hab_install_url,
    effortless_pkg  = var.effortless_pkg
    tmp_path        = local.tmp_path,
    jq_windows_url  = var.jq_windows_url,
    jq_linux_url    = var.jq_linux_url,
    clear_node_data = var.clear_node_data
  })
}

resource "null_resource" "effortless_bootstrap" {
  count    = local.instance_count

  triggers = {
    data      = md5(jsonencode(local.dna))
    ip        = md5(join(",", var.ips))
    installer = md5(local.installer)
  }

  connection {
    type        = var.system_type == "windows" ? "winrm" : "ssh"
    user        = element(compact(concat([var.user_name], var.user_names)), count.index)
    password    = length(compact(concat([var.user_pass], var.user_passes))) > 0 ? element(compact(concat([var.user_pass], var.user_passes)), count.index) : null
    private_key = length(compact(concat([var.user_private_key], var.user_private_keys))) > 0 ? file(element(compact(concat([var.user_private_key], var.user_private_keys)), count.index)) : null
    host        = var.ips[count.index]
  }

  provisioner "remote-exec" {
    inline = [
      "${local.mkdir} ${local.tmp_path}"
    ]
  }

  provisioner "file" {
    content     = local.installer
    destination = "${local.tmp_path}/${local.installer_name}"
  }

  provisioner "file" {
    content     = var.hook_data != "" ? var.hook_data : "no_hook_data_set"
    destination = "${local.tmp_path}/hook_data.json"
  }

  provisioner "file" {
    content     = length(local.dna_extra) != 0 ? jsonencode(local.dna_extra[count.index]) : jsonencode({"extra" = "data"})
    destination = "${local.tmp_path}/dna_extra.json"
  }

  provisioner "file" {
     content     = length(var.config) != 0 ? jsonencode(var.config[count.index]) : jsonencode({"base" = "data"})
    destination = "${local.tmp_path}/dna_base.json"
  }

  provisioner "remote-exec" {
    inline = [
      "${local.cmd} ${local.installer_cmd}"
    ]
  }
}

resource "random_string" "module_hook" {
  depends_on       = ["null_resource.effortless_bootstrap"]
  count            = local.instance_count
  length           = 16
  special          = true
  override_special = "/@\" "
}

data "null_data_source" "module_hook" {
  inputs = {
    data = jsonencode(random_string.module_hook[*].result)
  }
}
