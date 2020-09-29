locals {
  dna             = var.config
  cmd             = var.system_type == "linux" ? "bash" : "powershell.exe"
  mkdir           = var.system_type == "linux" ? "mkdir -p" : "${local.cmd} New-Item -ItemType Directory -Force -Path"
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
    clear_node_data = var.clear_node_data,
    ssl_cert_file   = var.ssl_cert_file,
    proxy_string    = var.proxy_string,
    no_proxy_string = var.no_proxy_string
  })
}

resource "null_resource" "effortless_bootstrap" {

  triggers = {
    data      = md5(jsonencode(local.dna))
    ip        = md5(var.ip)
    installer = md5(local.installer)
  }

  connection {
    type        = var.system_type == "windows" ? "winrm" : "ssh"
    user        = var.user_name
    password    = var.user_pass != "" ? var.user_pass : null
    private_key = var.user_private_key != "" ? file(var.user_private_key) : null
    host        = var.ip
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
     content     = length(var.config) != 0 ? jsonencode(var.config) : jsonencode({"base" = "data"})
    destination = "${local.tmp_path}/dna.json"
  }

  provisioner "remote-exec" {
    inline = [
      "${local.cmd} ${local.installer_cmd}"
    ]
  }

}
