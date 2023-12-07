

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
    cidr_blocks      = [aws_vpc.polka.cidr_block]
  }

   ingress {
    description      = "Polkadot"
    from_port        = 30333
    to_port          = 30333
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.polka.cidr_block]
  }

   ingress {
    description      = "Polkadot RPC"
    from_port        = 9933
    to_port          = 9933
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.polka.cidr_block]
  }

     ingress {
    description      = "Polkadot WS"
    from_port        = 9944
    to_port          = 9944
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.polka.cidr_block]
  }

  egress {
    description      = "Polkadot"
    from_port        = 30333
    to_port          = 30333
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.polka.cidr_block]
  }

    egress {
    description      = "Polkadot RPC"
    from_port        = 9933
    to_port          = 9933
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.polka.cidr_block]
  }

     egress {
    description      = "Polkadot WS"
    from_port        = 9944
    to_port          = 9944
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.polka.cidr_block]
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
// Ran into this issue  https://github.com/hashicorp/terraform-provider-aws/issues/26718

resource "aws_eip" "polka" {
  count               = length(aws_instance.polkanode)
  domain              = "vpc"
  instance            = aws_instance.polkanode[count.index].id
  associate_with_private_ip = aws_network_interface.polka[count.index].id    //errors indicated not to use ip address 
  depends_on                = [aws_network_interface_attachment.polka]
}

resource "aws_eip_association" "polka" {
  count               = length(aws_instance.polkanode)
  instance_id = aws_instance.polkanode[count.index].id
  allocation_id = aws_eip.polka[count.index].id
}


//COMPUTE

resource "aws_instance" "polkanode" {
  ami           = "ami-06dd92ecc74fdfb36"
  instance_type = "c6i.4xlarge"
  count         = 2
  cpu_options {
    core_count       = 4
    threads_per_core = 1
  }
  tags = {
    Name = "Polka ${count.index + 1}"
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
