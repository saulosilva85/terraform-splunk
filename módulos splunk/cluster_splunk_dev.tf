
# VPC e Subnets
/*resource "aws_vpc" "splunk_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "splunk_vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "splunk_igw" {
  vpc_id = aws_vpc.splunk_vpc.id

  tags = {
    Name = "splunk_igw"
  }
}

# Tabela de Rotas
resource "aws_route_table" "splunk_route_table" {
  vpc_id = aws_vpc.splunk_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.splunk_igw.id
  }

  tags = {
    Name = "splunk_route_table"
  }
}

# Associação das Subnets à Tabela de Rotas
resource "aws_route_table_association" "splunk_subnet_a_association" {
  subnet_id      = aws_subnet.splunk_subnet_a.id
  route_table_id = aws_route_table.splunk_route_table.id
}

resource "aws_route_table_association" "splunk_subnet_b_association" {
  subnet_id      = aws_subnet.splunk_subnet_b.id
  route_table_id = aws_route_table.splunk_route_table.id
}

resource "aws_route_table_association" "splunk_subnet_c_association" {
  subnet_id      = aws_subnet.splunk_subnet_c.id
  route_table_id = aws_route_table.splunk_route_table.id
}

# Subnets
resource "aws_subnet" "splunk_subnet_a" {
  vpc_id            = aws_vpc.splunk_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet_aza"
  }
}

resource "aws_subnet" "splunk_subnet_b" {
  vpc_id            = aws_vpc.splunk_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "subnet_azb"
  }
}

resource "aws_subnet" "splunk_subnet_c" {
  vpc_id            = aws_vpc.splunk_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "subnet_azc"
  }
}

# Security Group
resource "aws_security_group" "splunk_sg" {
  name        = "splunk_sg"
  vpc_id      = aws_vpc.splunk_vpc.id
  description = "Allow Splunk traffic, SSH, HTTP, HTTPS"

  # Regra para tráfego SSH (Porta 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regra para tráfego HTTP (Porta 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regra para tráfego HTTPS (Porta 443)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regra para portas 8000 a 8088 (Splunk)
  ingress {
    from_port   = 8000
    to_port     = 8088
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regra de saída para todo o tráfego
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Load Balancer
resource "aws_lb" "splunk_lb" {
  name               = "splunk-sh-dev-routed-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.splunk_sg.id]
  subnets            = [aws_subnet.splunk_subnet_a.id, aws_subnet.splunk_subnet_b.id, aws_subnet.splunk_subnet_c.id]
}

# Target Group
resource "aws_lb_target_group" "splunk_tg" {
  name     = "splunk-sh-dev-routed-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.splunk_vpc.id
}

# Listener
resource "aws_lb_listener" "splunk_listener" {
  load_balancer_arn = aws_lb.splunk_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.splunk_tg.arn
  }
}

# Instances para Splunk Management, SH Cluster, e Indexers
variable "ebs_volume_size" {
  description = "Tamanho do volume EBS em GB"
  type        = number
  default     = 20  # Informar o Tamanho do volume EBS
}

resource "aws_instance" "splunk_mgmt" {
  ami                = "ami-0fff1b9a61dec8a5f"
  instance_type      = "t2.micro"
  subnet_id          = aws_subnet.splunk_subnet_a.id
  vpc_security_group_ids = [aws_security_group.splunk_sg.id]
  associate_public_ip_address = true  # Adiciona IP público à instância

  root_block_device {
    volume_size = var.ebs_volume_size
    volume_type = "gp2"  # Tipo de volume EBS
  }

  tags = {
    Name = "splunk_manager-cluster-001"
  }
}

resource "aws_instance" "splunk_sh" {
  count              = 3  # Informar quantidade de instancias Search Head no cluster
  ami                = "ami-0fff1b9a61dec8a5f"
  instance_type      = "t2.micro"
  subnet_id          = element([aws_subnet.splunk_subnet_a.id, aws_subnet.splunk_subnet_b.id, aws_subnet.splunk_subnet_c.id], count.index)
  vpc_security_group_ids = [aws_security_group.splunk_sg.id]
  associate_public_ip_address = true  # Adiciona IP público à instância

  root_block_device {
    volume_size = var.ebs_volume_size
    volume_type = "gp2"  # Tipo de volume EBS
  }

  tags = {
    Name = "sh-cluster-001"
  }
}

resource "aws_instance" "splunk_idx" {
  count              = 3  # Informar quantidade de instancias Indexers no cluster
  ami                = "ami-0fff1b9a61dec8a5f"
  instance_type      = "t2.micro"
  subnet_id          = element([aws_subnet.splunk_subnet_a.id, aws_subnet.splunk_subnet_b.id, aws_subnet.splunk_subnet_c.id], count.index)
  vpc_security_group_ids = [aws_security_group.splunk_sg.id]
  associate_public_ip_address = true  # Adiciona IP público à instância

  root_block_device {
    volume_size = var.ebs_volume_size
    volume_type = "gp2"  # Tipo de volume EBS
  }

  tags = {
    Name = "indexer-cluster-001"
  }
}

# Target Group Attachment
resource "aws_lb_target_group_attachment" "splunk_mgmt_tg" {
  target_group_arn = aws_lb_target_group.splunk_tg.arn
  target_id        = aws_instance.splunk_mgmt.id
  port             = 8000
}

resource "aws_lb_target_group_attachment" "splunk_sh_tg" {
  count            = 3
  target_group_arn = aws_lb_target_group.splunk_tg.arn
  target_id        = aws_instance.splunk_sh[count.index].id
  port             = 8000
}

/*resource "aws_lb_target_group_attachment" "splunk_idx_tg" {
  count            = 3
  target_group_arn = aws_lb_target_group.splunk_tg.arn
  target_id        = aws_instance.splunk_idx[count.index].id
  port             = 8000
}*/
