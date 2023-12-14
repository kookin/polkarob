//LOCAL VARS

locals {
  ssh_user ="ubuntu"
  key_name ="polka"
  private_key_path ="~/Desktop/polka.cer"
  vpc_id = "vpc-06f39ba13d867f125"    //default vpc
}

// NETWORKING

// sec group

resource "aws_security_group" "polka" {
  name        = "polka"
  description = "polkadot"
  vpc_id      = local.vpc_id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

   ingress {
    description      = "Polkadot"
    from_port        = 30333
    to_port          = 30333
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "Polkadot"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "Polkadot"
    from_port        = 30333
    to_port          = 30333
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Polkadot Ports"
  }
}


//COMPUTE

resource "aws_instance" "polkanode" {
  ami           = "ami-06dd92ecc74fdfb36"
  instance_type = "c6i.4xlarge"
  count         = 2
  associate_public_ip_address = true
  key_name = local.key_name
  availability_zone = "eu-central-1a"
  vpc_security_group_ids = [
    aws_security_group.polka.id
  ]
  cpu_options {
    core_count       = 4
    threads_per_core = 1
  }

   root_block_device {
    volume_size = 1024
    volume_type = "gp2" 
  }

  tags = {
    Name = "Polkarob_${count.index + 1}"
  }

}


//ANSIBLE

locals {
  // ansible_inventory_var = join("\n", concat(["[polkadot_nodes]"], [for instance in aws_instance.polkanode : instance.public_ip]))
  ansible_inventory_var = join("\n", concat(["[polkadot_nodes]"], [for instance in aws_instance.polkanode : "${instance.tags.Name} ansible_ssh_host=${instance.public_ip}"]))

}

resource "null_resource" "polkanode" {

  count = length(aws_instance.polkanode)

  triggers = {
    content = local.ansible_inventory_var
  }

  provisioner "remote-exec" {
    inline = ["echo 'Starting SSH'"]
    connection {
      type        = "ssh"
      user        = local.ssh_user
      private_key = file(local.private_key_path)
      host        = element(aws_instance.polkanode[*].public_ip, count.index)
    }
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "${local.ansible_inventory_var}" > inventory.ini
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -vvv -i inventory.ini --private-key ${local.private_key_path} -u ${local.ssh_user} -b polka.yaml
    EOT
  }
}