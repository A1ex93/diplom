data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2404-lts-oslogin"
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

# === VPC ===
resource "yandex_vpc_network" "main" {
  name = "production-network"
}

# === Managed NAT Gateway ===
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

# Таблица маршрутов для NAT
resource "yandex_vpc_route_table" "to-internet" {
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

# === ПОДСЕТИ ===
resource "yandex_vpc_subnet" "public" {
  name           = "public-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.1.0/24"]
  route_table_id = yandex_vpc_route_table.to-internet.id
}

resource "yandex_vpc_subnet" "private-web-b" {
  name           = "private-web-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.2.0/24"]
  route_table_id = yandex_vpc_route_table.to-internet.id
}

resource "yandex_vpc_subnet" "private-web-d" {
  name           = "private-web-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.3.0/24"]
  route_table_id = yandex_vpc_route_table.to-internet.id
}

resource "yandex_vpc_subnet" "private-data" {
  name           = "private-data"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.4.0/24"]
  route_table_id = yandex_vpc_route_table.to-internet.id
}

# ГРУППЫ БЕЗОПАСНОСТИ 

# 1. Группа безопасности для SSH Bastion
resource "yandex_vpc_security_group" "ssh_bastion" {
  name        = "ssh-bastion"
  description = "Security group for SSH Bastion host"

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Группа безопасности для веб-доступа
resource "yandex_vpc_security_group" "allow_web" {
  name        = "allow-web"
  description = "Security group for web traffic"

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

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Группа безопасности для Elasticsearch
resource "yandex_vpc_security_group" "elasticsearch_sg" {
  name        = "elasticsearch-sg"
  description = "Security group for Elasticsearch"

  ingress {
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Группа безопасности для Kibana
resource "yandex_vpc_security_group" "kibana_sg" {
  name        = "kibana-sg"
  description = "Security group for Kibana"

  ingress {
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# 5. Группа безопасности для внутреннего SSH
resource "yandex_vpc_security_group" "internal_ssh" {
  name        = "internal-ssh"
  description = "Security group for internal SSH access"

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["10.0.1.24/32"]
  }

  ingress {
    protocol       = "TCP"
    from_port      = 10050
    to_port        = 10051
    v4_cidr_blocks = ["10.0.1.17/32"]
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "yandex_dns_zone" "internal_zone" {
  name        = "internal-zone"
  description = "Internal DNS zone for VMs"
  zone        = "ru-central1.internal."
  public      = false
  private_networks = [yandex_vpc_network.main.id]  # Критически важная строка
}

resource "yandex_vpc_security_group" "kibana" {
  name       = "kibana-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "es" {
  name       = "elasticsearch-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# === BASTION HOST ===
resource "yandex_compute_instance" "bastion" {
  name        = "bastion-host"
  hostname    = "bastion.ru-central.internal"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
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
      dns_record {
        fqdn = "bastion"
        dns_zone_id = yandex_dns_zone.internal_zone.id
       
      }

    security_group_ids = [
      yandex_vpc_security_group.bastion.id,
      yandex_vpc_security_group.internal_traffic.id
    ]
  }



  metadata = {
    ssh-keys          = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    serial-port-enable = 1
    user-data         = local.common_user_data
  }
}

# === WEB-СЕРВЕР 1 ===
resource "yandex_compute_instance" "web_1" {
  name        = "web-1"
  hostname    = "web-1.ru-central.internal"
  zone        = "ru-central1-b"
  platform_id = "standard-v3"

  scheduling_policy {
    preemptible = true
  }

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
    subnet_id          = yandex_vpc_subnet.private-web-b.id
    security_group_ids = [
      yandex_vpc_security_group.web.id,
      yandex_vpc_security_group.internal_ssh.id,
      yandex_vpc_security_group.internal_traffic.id
    ]
      dns_record {
        fqdn = "web-1"
        dns_zone_id = yandex_dns_zone.internal_zone.id
       
      }
  }

  metadata = {
    user-data = local.common_user_data
  }
}

# === WEB-СЕРВЕР 2 ===
resource "yandex_compute_instance" "web_2" {
  name        = "web-2"
  hostname    = "web-2.ru-central.internal"
  zone        = "ru-central1-d"
  platform_id = "standard-v3"

  scheduling_policy {
    preemptible = true
  }

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
    subnet_id          = yandex_vpc_subnet.private-web-d.id
    security_group_ids = [
      yandex_vpc_security_group.web.id,
      yandex_vpc_security_group.internal_ssh.id,
      yandex_vpc_security_group.internal_traffic.id
    ]

      dns_record {
        fqdn = "web-2"
        dns_zone_id = yandex_dns_zone.internal_zone.id
       
      }


  }

  metadata = {
    user-data = local.common_user_data
  }
}

# === KIBANA ===
resource "yandex_compute_instance" "kibana" {
  name        = "kibana"
  hostname    = "kibana.ru-central.internal"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"

  scheduling_policy {
    preemptible = true
  }

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
      yandex_vpc_security_group.kibana.id,
      yandex_vpc_security_group.internal_traffic.id
    ]
      dns_record {
        fqdn = "kibana"
        dns_zone_id = yandex_dns_zone.internal_zone.id
     
      }

  }

  metadata = {
    user-data = local.common_user_data
  }
}

# === ZABBIX SERVER ===
resource "yandex_compute_instance" "zabbix_server" {
  name        = "zabbix-server"
  hostname    = "zabbix.ru-central.internal"
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
      yandex_vpc_security_group.internal_traffic.id
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

# === ELASTICSEARCH ===
resource "yandex_compute_instance" "elasticsearch" {
  name        = "elasticsearch"
  hostname    = "el.ru-central.internal"
  zone        = "ru-central1-d"
  platform_id = "standard-v3"

  scheduling_policy {
    preemptible = true
  }
  resources {
    cores  = 2
    memory = 4
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 30
    }
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.private-data.id
    security_group_ids = [
      yandex_vpc_security_group.es.id,
      yandex_vpc_security_group.internal_ssh.id,
      yandex_vpc_security_group.internal_traffic.id
    ]

      dns_record {
        fqdn = "el"
        dns_zone_id = yandex_dns_zone.internal_zone.id
      }
 }
  metadata = {
    user-data = local.common_user_data
  }
}
                        

