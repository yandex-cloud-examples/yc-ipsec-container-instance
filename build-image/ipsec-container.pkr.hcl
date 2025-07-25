# ===============================================================
# IPsec strongSwan IPsec image build configuration
# https://docs.strongswan.org/docs/latest
# ===============================================================

variable "YC_FOLDER_ID" {
  type = string
  default = env("YC_FOLDER_ID")
}

variable "YC_ZONE" {
  type = string
  default = env("YC_ZONE")
}

variable "YC_SUBNET_ID" {
  type = string
  default = env("YC_SUBNET_ID")
}

variable "SWAN_VER" {
  type = string
  default = "6.0.2"
}

variable "HOME_DIR" {
  type = string
  default = "/home/ubuntu"
}


source "yandex" "ipsec-container-instance" {
  folder_id           = "${var.YC_FOLDER_ID}"
  platform_id         = "standard-v3"
  source_image_family = "ubuntu-2404-lts"
  ssh_username        = "ubuntu"
  use_ipv4_nat        = "true"
  image_description   = "IPsec Container Instance"
  image_family        = "ipsec-container-instance"
  image_name          = "ipsec-container-instance"
  subnet_id           = "${var.YC_SUBNET_ID}"
  disk_type           = "network-ssd"
  disk_size_gb        = "30"
  zone                = "${var.YC_ZONE}"
}

build {
  sources = ["source.yandex.ipsec-container-instance"]
  provisioner "file" {
    source = "ipsec-container-setup.sh"
    destination = "ipsec-container-setup.sh"
  }
  provisioner "file" {
    source = "./strongswan"
    destination = "${var.HOME_DIR}/strongswan"
  }
  provisioner "file" {
    source = "./web-hc"
    destination = "${var.HOME_DIR}/web-hc"
  }
  provisioner "file" {
    source = "update-routes.sh"
    destination = "${var.HOME_DIR}/update-routes.sh"
  }
  provisioner "file" {
    source = "ipsec-init.sh"
    destination = "${var.HOME_DIR}/ipsec-init.sh"
  }

  provisioner "shell" {
    pause_before = "3s"
    environment_vars = [
      "HOME_DIR=${var.HOME_DIR}",
      "SWAN_VER=${var.SWAN_VER}"
    ]
    execute_command = "sudo {{ .Vars }} bash '{{ .Path }}'"
    scripts = [
      "ipsec-container-setup.sh"
    ]
  }
}
