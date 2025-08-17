

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
      yandex_vpc_security_group.allow_web.id,
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
