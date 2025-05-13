
# VPC
/*resource "aws_vpc" "splunk_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Subnets públicas para as três zonas de disponibilidade
resource "aws_subnet" "public_subnet_az1" {
  vpc_id                  = aws_vpc.splunk_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"  # Alterar para a zona desejada
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet_az2" {
  vpc_id                  = aws_vpc.splunk_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet_az3" {
  vpc_id                  = aws_vpc.splunk_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.splunk_vpc.id
}

# Route Table
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.splunk_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Associar subnets à tabela de rotas
resource "aws_route_table_association" "subnet_assoc_az1" {
  subnet_id      = aws_subnet.public_subnet_az1.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "subnet_assoc_az2" {
  subnet_id      = aws_subnet.public_subnet_az2.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "subnet_assoc_az3" {
  subnet_id      = aws_subnet.public_subnet_az3.id
  route_table_id = aws_route_table.public_route.id
}

# Grupos de segurança
resource "aws_security_group" "splunk_sg" {
  vpc_id = aws_vpc.splunk_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8089
    to_port     = 8089
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ELB para os Search Heads
resource "aws_elb" "splunk_elb" {
  name               = "splunk-elb"
  availability_zones = [aws_subnet.public_subnet_az1.availability_zone, aws_subnet.public_subnet_az2.availability_zone, aws_subnet.public_subnet_az3.availability_zone]

  listener {
    instance_port     = 8000
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:8000/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  instances = [
    aws_instance.search_head_1.id,
    aws_instance.search_head_2.id,
    aws_instance.search_head_3.id,
  ]

  security_groups = [aws_security_group.splunk_sg.id]
}

# Variável para definir o tamanho do disco EBS
variable "ebs_size" {
  description = "Tamanho do disco EBS em GB"
  default     = 10  # Informar tamanho desejado do disco
}

# Instâncias EC2 (Search Heads, Indexers, Deployer, Cluster Master)
resource "aws_instance" "search_head_1" {
  ami           = "ami-0fff1b9a61dec8a5f"  # Alterar para a AMI Splunk
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.public_subnet_az1.id
  security_groups = [aws_security_group.splunk_sg.id]

  tags = {
    Name = "search_head_1"
  }

  # Configuração do disco EBS
  ebs_block_device {
    device_name = "/dev/xvda"  # Nome do dispositivo EBS
    volume_size = var.ebs_size  # Tamanho do disco definido pela variável
    volume_type = "gp2"  # Tipo do volume (pode ser alterado para gp3, io1, etc.)
    delete_on_termination = true  # Apagar o EBS ao encerrar a instância
  }
}

resource "aws_instance" "search_head_2" {
  ami           = "ami-0fff1b9a61dec8a5f"
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.public_subnet_az2.id
  security_groups = [aws_security_group.splunk_sg.id]

  tags = {
    Name = "search_head_2"
  }

  # Configuração do disco EBS
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = var.ebs_size
    volume_type = "gp2"
    delete_on_termination = true
  }
}

resource "aws_instance" "search_head_3" {
  ami           = "ami-0fff1b9a61dec8a5f"
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.public_subnet_az3.id
  security_groups = [aws_security_group.splunk_sg.id]

  tags = {
    Name = "search_head_3"
  }

  # Configuração do disco EBS
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = var.ebs_size
    volume_type = "gp2"
    delete_on_termination = true
  }
}

resource "aws_instance" "indexer_1" {
  ami           = "ami-0fff1b9a61dec8a5f"
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.public_subnet_az1.id
  security_groups = [aws_security_group.splunk_sg.id]

  tags = {
    Name = "indexer_1"
  }

  # Configuração do disco EBS
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = var.ebs_size
    volume_type = "gp2"
    delete_on_termination = true
  }
}

resource "aws_instance" "indexer_2" {
  ami           = "ami-0fff1b9a61dec8a5f"
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.public_subnet_az2.id
  security_groups = [aws_security_group.splunk_sg.id]

  tags = {
    Name = "indexer_2"
  }

  # Configuração do disco EBS
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = var.ebs_size
    volume_type = "gp2"
    delete_on_termination = true
  }
}

resource "aws_instance" "indexer_3" {
  ami           = "ami-0fff1b9a61dec8a5f"
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.public_subnet_az3.id
  security_groups = [aws_security_group.splunk_sg.id]

  tags = {
    Name = "indexer_3"
  }

  # Configuração do disco EBS
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = var.ebs_size
    volume_type = "gp2"
    delete_on_termination = true
  }
}

resource "aws_instance" "deployer" {
  ami           = "ami-0fff1b9a61dec8a5f"
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.public_subnet_az1.id
  security_groups = [aws_security_group.splunk_sg.id]

  tags = {
    Name = "deployer"
  }

  # Configuração do disco EBS
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = var.ebs_size
    volume_type = "gp2"
    delete_on_termination = true
  }
}

resource "aws_instance" "cluster_master" {
  ami           = "ami-0fff1b9a61dec8a5f"
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.public_subnet_az1.id
  security_groups = [aws_security_group.splunk_sg.id]

  tags = {
    Name = "master"
  }

  # Configuração do disco EBS
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = var.ebs_size
    volume_type = "gp2"
    delete_on_termination = true
  }
}*/