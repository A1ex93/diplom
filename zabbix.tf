data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2404-lts-oslogin"
}

data "yandex_vpc_network" "main" {
  name = "production-network"
}

locals {
  common_user_data = <<EOF
#cloud-config
users:
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    passwd: "$6$rounds=4096$salt$IxDD3jeSOb5eQ1JY5XQ6.3cPp6X7vR/GdI4WXzXjUEdiL7q9Vz6L1Zz5LQ1rL1WXq1eF6XU1eD5Xe1eQ1eG5Xe1"
    lock_passwd: false
    ssh_pwauth: true
chpasswd:
  list: |
    ubuntu:ubuntu
  expire: false
runcmd:
  - mkdir -p /var/lib/cloud/instance/warnings/
  - touch /var/lib/cloud/instance/warnings/.skip
EOF
}


# === ГРУППЫ БЕЗОПАСНОСТИ ===
# Новая группа для внутреннего трафика
resource "yandex_vpc_security_group" "zabbix_v2" {
  name       = "allow-zabbix"
  network_id = data.yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol       = "TCP"
    port           = 10051
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol       = "TCP"
    port           = 10050
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "internal_traffic" {
  name        = "internal-traffic"
  description = "Allow all internal traffic between subnets"
  network_id  = data.yandex_vpc_network.main.id

  ingress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
  }

  ingress {
    protocol       = "ICMP"
    v4_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "yandex_dns_zone" "internal_zone" {
  name        = "internal-zone"
  description = "Internal DNS zone for VMs"
  zone        = "ru-central1.internal."
  public      = false
  private_networks = [data.yandex_vpc_network.main.id]  # Критически важная строка
}

resource "yandex_vpc_security_group" "internal_ssh" {
  name       = "internal-ssh"
  network_id = data.yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["10.0.1.0/24"] # SSH только из bastion
  }
}

resource "yandex_vpc_subnet" "public" {
  name           = "public-subnet"
  zone           = "ru-central1-a"
  network_id     = data.yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.1.0/24"]
  route_table_id = yandex_vpc_route_table.to-internet.id
}
# Таблица маршрутов для NAT
resource "yandex_vpc_route_table" "to-internet" {
  network_id = data.yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}
# === Managed NAT Gateway ===
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}



# === ZABBIX SERVER ===
resource "yandex_compute_instance" "zabbix_server" {
  name        = "zabbix-server"
  hostname    = "zabbixserver.ru-central.internal"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"
  resources {
    cores  = 2
    memory = 4
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
    }
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    nat                = true
    security_group_ids = [
      yandex_vpc_security_group.internal_ssh.id,
      yandex_vpc_security_group.internal_traffic.id,
      yandex_vpc_security_group.zabbix_v2.id
    ]
      dns_record {
        fqdn = "zabbix"
        dns_zone_id = yandex_dns_zone.internal_zone.id
      }
  }
  metadata = {
    user-data = local.common_user_data
  }
}
