//LOCAL VARS

locals {
  ssh_user ="ubuntu"
  key_name ="ub"
  private_key_path ="~/Desktop/ub.cer"
}

// NETWORKING

// vpc

resource "aws_vpc" "polka" {
  cidr_block = "10.0.0.0/24"
}

resource "aws_internet_gateway" "polka" {
  vpc_id = aws_vpc.polka.id
}

resource "aws_security_group" "polka" {
  name        = "polka"
  description = "polkadot"
  vpc_id      = aws_vpc.polka.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

   ingress {
    description      = "Polkadot"
    from_port        = 30333
    to_port          = 30333
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    description      = "Polkadot"
    from_port        = 30333
    to_port          = 30333
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Polkadot Ext Ports"
  }
}

resource "aws_route_table" "polka" {
  vpc_id = aws_vpc.polka.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.polka.id
  }
}

resource "aws_subnet" "polka" {
  vpc_id     = aws_vpc.polka.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "eu-central-1a"
 
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.polka.id
  route_table_id = aws_route_table.polka.id
}


//private ips

//Thought I needed these for ansible, but it seems not. Left them in anyway


resource "aws_network_interface" "polka" {
  count             = length(aws_instance.polkanode)
  subnet_id         = aws_subnet.polka.id
  private_ips       = ["10.0.0.${51 + count.index}"]
  security_groups   = [aws_security_group.polka.id]
}

resource "aws_network_interface_attachment" "polka" {
  count               = length(aws_instance.polkanode)
  instance_id         = aws_instance.polkanode[count.index].id
  network_interface_id = aws_network_interface.polka[count.index].id
  depends_on          = [aws_security_group.polka] 
  device_index        = 1
}


// public ips
// thought I needed to set  eip

//resource "aws_eip" "polka" {
//  count               = length(aws_instance.polkanode)
//  domain              = "vpc"
//  instance            = aws_instance.polkanode[count.index].id
//  associate_with_private_ip = aws_network_interface.polka[count.index].id    //errors indicated not to use ip address 
//  depends_on                = [aws_network_interface_attachment.polka]
// }

//resource "aws_eip_association" "polka" {
 // count               = length(aws_instance.polkanode)
//  instance_id = aws_instance.polkanode[count.index].id
//  allocation_id = aws_eip.polka[count.index].id
// }


//COMPUTE

resource "aws_instance" "polkanode" {
  ami           = "ami-06dd92ecc74fdfb36"
  instance_type = "c6i.4xlarge"
  count         = 2
  associate_public_ip_address = true
  cpu_options {
    core_count       = 4
    threads_per_core = 1
  }
  tags = {
    Name = "Polka ${count.index + 1}"
  }
  provisioner "remote-exec" {
   inline = ["echo 'Starting SSH'"] 
   connection {
    type = "ssh"
    user = local.ssh_user
    private_key = file(local.private_key_path)
    host = aws_instance.polkanodetest.public_ip
   }
}

  provisioner "local-exec" {
    command = "ansible-playbook -i  $(aws_instance.polkanode.public_ip), --private-key $(local.private_key_path) polka.yaml"
  
}
}


//STORAGE

resource "aws_ebs_volume" "polkavol" {
  count             = length(aws_instance.polkanode)
  availability_zone = "eu-central-1a"
  size              = 1024
  type              = "gp2"
}

resource "aws_volume_attachment" "ebs_att" {
  count        = length(aws_instance.polkanode)
  device_name  = "/dev/sdh"
  volume_id    = aws_ebs_volume.polkavol[count.index].id
  instance_id  = aws_instance.polkanode[count.index].id
}
