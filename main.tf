resource "openstack_networking_router_v2" "ipa_router" {
  name              = "ipa_router"
  admin_state_up    = "true"
}

resource "openstack_networking_network_v2" "ipa_network" {
  name              = "ipa_network"
  admin_state_up    = "true"
  shared            = "false"
}

resource "openstack_networking_subnet_v2" "ipa_subnet" {
  name              = "ipa_subnet"
  network_id        = openstack_networking_network_v2.ipa_network.id
  cidr              = "10.1.0.0/24"
  ip_version        = 4
  gateway_ip        = "10.1.0.254"
  allocation_pool {
    start   = "10.1.0.1"
    end     = "10.1.0.5"
  }
}

resource "openstack_networking_router_interface_v2" "ipa_interface" {
  router_id = openstack_networking_router_v2.ipa_router.id
  subnet_id = openstack_networking_subnet_v2.ipa_subnet.id
}

# Create ports
resource "openstack_networking_port_v2" "primary_freeipa" {
  name                  = "primary_freeipa"
  network_id            = openstack_networking_network_v2.ipa_network.id
  admin_state_up        = "true"
  port_security_enabled = "false"
  fixed_ip {
    subnet_id   = openstack_networking_subnet_v2.ipa_subnet.id
    ip_address  = "10.1.0.2"
  }
}

resource "openstack_networking_port_v2" "replica1_freeipa" {
  name                  = "replica1_freeipa"
  network_id            = openstack_networking_network_v2.ipa_network.id
  admin_state_up        = "true"
  port_security_enabled = "false"
  fixed_ip {
    subnet_id   = openstack_networking_subnet_v2.ipa_subnet.id
    ip_address  = "10.1.0.3"
  }
}

resource "openstack_networking_port_v2" "replica2_freeipa" {
  name                  = "replica2_freeipa"
  network_id            = openstack_networking_network_v2.ipa_network.id
  admin_state_up        = "true"
  port_security_enabled = "false"
  fixed_ip {
    subnet_id   = openstack_networking_subnet_v2.ipa_subnet.id
    ip_address  = "10.1.0.4"
  }
}

resource "openstack_networking_port_v2" "chef_zero_freeipa" {
  name                  = "chef_zero_freeipa"
  network_id            = openstack_networking_network_v2.ipa_network.id
  admin_state_up        = "true"
  port_security_enabled = "false"
  fixed_ip {
    subnet_id   = openstack_networking_subnet_v2.ipa_subnet.id
    ip_address  = "10.1.0.5"
  }
}

# Create instances
resource "openstack_networking_port_v2" "chef_zero" {
    name            = "chef_zero"
    admin_state_up  = "true"
    network_id      = data.openstack_networking_network_v2.public.id
}

resource "openstack_compute_instance_v2" "chef_zero" {
    name            = "chef_zero"
    image_name      = var.docker_image_name
    flavor_name     = "m2.local.2c3m10d"
    key_pair        = var.ssh_key_name
    security_groups = ["default"]
    user_data       = <<-EOF
        #cloud-config
        packages:
          - dnsmasq
        write_files:
          - path: /etc/dnsmasq.conf
            content: |
              listen-address=0.0.0.0
              bind-interfaces
              server=140.211.166.130
              server=140.211.166.131
              addn-hosts=/etc/dnsmasq.hosts
              server=/testing.osuosl.org/10.1.0.2
          - path: /etc/dnsmasq.hosts
            content: |
                10.1.0.2 primary.testing.osuosl.org primary
                10.1.0.3 replica1.testing.osuosl.org replica1
                10.1.0.4 replica2.testing.osuosl.org replica2
        runcmd:
          - systemctl enable dnsmasq
          - systemctl restart dnsmasq
    EOF
    connection {
        user = "almalinux"
        host = openstack_networking_port_v2.chef_zero.all_fixed_ips.0
    }
    network {
        port = openstack_networking_port_v2.chef_zero.id
    }

    network {
        port = openstack_networking_port_v2.chef_zero_freeipa.id
    }

    provisioner "remote-exec" {
        inline = [
            "until [ -S /var/run/docker.sock ] ; do sleep 1 && echo 'docker not started...' ; done",
            "sudo docker run -d -p 8889:8889 --name chef-zero osuosl/chef-zero"
        ]
    }
    provisioner "local-exec" {
        command = "rake knife_upload"
        environment = {
            CHEF_SERVER = "${openstack_compute_instance_v2.chef_zero.network.0.fixed_ip_v4}"
        }
    }
}

resource "openstack_networking_port_v2" "primary" {
    name            = "primary"
    admin_state_up  = true
    network_id      = data.openstack_networking_network_v2.public.id
}

resource "openstack_compute_instance_v2" "primary" {
    name            = "primary"
    image_name      = var.os_image
    flavor_name     = "m2.local.4c4m50d"
    key_pair        = var.ssh_key_name
    security_groups = ["default"]
    user_data       = <<-EOF
        #cloud-config
        write_files:
          - path: /etc/resolv.conf
            content: |
                nameserver ${openstack_compute_instance_v2.chef_zero.network.0.fixed_ip_v4}
    EOF
    connection {
        user = "almalinux"
        host = openstack_networking_port_v2.primary.all_fixed_ips.0
    }
    network {
        port = openstack_networking_port_v2.primary.id
    }
    network {
        port = openstack_networking_port_v2.primary_freeipa.id
    }

    provisioner "remote-exec" {
        inline = ["echo online"]
    }
}

resource "null_resource" "primary" {
    provisioner "local-exec" {
        command = <<-EOF
            knife bootstrap -c test/chef-config/knife.rb \
            ${var.ssh_user_name}@${openstack_compute_instance_v2.primary.network.0.fixed_ip_v4} \
            -y -N primary --sudo --bootstrap-version ${var.chef_version} \
            -r 'recipe[multi-node::primary]'
            EOF
        environment = {
            CHEF_SERVER = "${openstack_compute_instance_v2.chef_zero.network.0.fixed_ip_v4}"
        }
    }
    depends_on = [
        openstack_compute_instance_v2.primary,
    ]
}

resource "openstack_networking_port_v2" "replica1" {
    name            = "replica1"
    admin_state_up  = true
    network_id      = data.openstack_networking_network_v2.public.id
}

resource "openstack_compute_instance_v2" "replica1" {
    name            = "replica1"
    image_name      = var.os_image
    flavor_name     = "m2.local.4c4m50d"
    key_pair        = var.ssh_key_name
    security_groups = ["default"]
    user_data       = <<-EOF
        #cloud-config
        write_files:
          - path: /etc/resolv.conf
            content: |
                nameserver ${openstack_compute_instance_v2.chef_zero.network.0.fixed_ip_v4}
    EOF
    connection {
        user = "almalinux"
        host = openstack_networking_port_v2.replica1.all_fixed_ips.0
    }
    network {
        port = openstack_networking_port_v2.replica1.id
    }
    network {
        port = openstack_networking_port_v2.replica1_freeipa.id
    }
    provisioner "remote-exec" {
        inline = ["echo online"]
    }
}

resource "null_resource" "replica1" {
    provisioner "local-exec" {
        command = <<-EOF
            knife bootstrap -c test/chef-config/knife.rb \
            ${var.ssh_user_name}@${openstack_compute_instance_v2.replica1.network.0.fixed_ip_v4} \
            -y -N replica1 --sudo --bootstrap-version ${var.chef_version} \
            -r 'recipe[multi-node::replica1]'
        EOF
        environment = {
            CHEF_SERVER = "${openstack_compute_instance_v2.chef_zero.network.0.fixed_ip_v4}"
        }
    }
    depends_on = [
        openstack_compute_instance_v2.replica1,
        null_resource.primary
    ]
}

resource "openstack_networking_port_v2" "replica2" {
    name            = "replica2"
    admin_state_up  = true
    network_id      = data.openstack_networking_network_v2.public.id
}

resource "openstack_compute_instance_v2" "replica2" {
    name            = "replica2"
    image_name      = var.os_image
    flavor_name     = "m2.local.4c4m50d"
    key_pair        = var.ssh_key_name
    security_groups = ["default"]
    user_data       = <<-EOF
        #cloud-config
        write_files:
          - path: /etc/resolv.conf
            content: |
                nameserver ${openstack_compute_instance_v2.chef_zero.network.0.fixed_ip_v4}
    EOF
    connection {
        user = "almalinux"
        host = openstack_networking_port_v2.replica2.all_fixed_ips.0
    }
    network {
        port = openstack_networking_port_v2.replica2.id
    }
    network {
        port = openstack_networking_port_v2.replica2_freeipa.id
    }
    provisioner "remote-exec" {
        inline = ["echo online"]
    }
}

resource "null_resource" "replica2" {
    provisioner "local-exec" {
        command = <<-EOF
            knife bootstrap -c test/chef-config/knife.rb \
            ${var.ssh_user_name}@${openstack_compute_instance_v2.replica2.network.0.fixed_ip_v4} \
            -y -N replica2 --sudo --bootstrap-version ${var.chef_version} \
            -r 'recipe[multi-node::replica2]'
        EOF
        environment = {
            CHEF_SERVER = "${openstack_compute_instance_v2.chef_zero.network.0.fixed_ip_v4}"
        }
    }
    depends_on = [
        openstack_compute_instance_v2.replica2,
        null_resource.primary
    ]
}
