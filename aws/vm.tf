data "aws_ami" "debian" {
  most_recent = true
  filter {
    name   = "name"
    values = ["debian-11-amd64-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["136693071363"] # Debian
}

# Create a random password for the web UI
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_vpc" "ollama" {
  cidr_block           = "10.1.0.0/24"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "subnet" {
  cidr_block        = cidrsubnet(aws_vpc.ollama.cidr_block, 3, 1)
  vpc_id            = aws_vpc.ollama.id
  availability_zone = "${var.region}a"
}

resource "aws_internet_gateway" "ollama" {
  vpc_id = aws_vpc.ollama.id
}

resource "aws_route_table" "ollama" {
  vpc_id = aws_vpc.ollama.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ollama.id
  }
}

resource "aws_route_table_association" "ollama" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.ollama.id
}

resource "aws_security_group" "ssh" {
  name = "allow-all"

  vpc_id = aws_vpc.ollama.id

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "http" {
  name = "allow-all-http"

  vpc_id = aws_vpc.ollama.id

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "ollama" {
  key_name   = "ollama"
  public_key = file(var.ssh_pub_key)
}

resource "aws_instance" "ollama" {
  ami           = data.aws_ami.debian.id
  instance_type = var.gpu_enabled ? var.machine.gpu.type : var.machine.cpu.type
  key_name      = resource.aws_key_pair.ollama.key_name

  associate_public_ip_address = true

  security_groups = [
    "${aws_security_group.ssh.id}",
    "${aws_security_group.http.id}"
    ]
  subnet_id       = aws_subnet.subnet.id

  user_data_base64 = base64encode(templatefile("${path.module}/scripts/init.sh",
    {
      gpu_enabled          = var.gpu_enabled
      open_webui_password = random_password.password.result
      openai_key         = var.openai_key
  }))
}

# Create a terracurl request to check if the web server is up and running
# Wait a max of 20 minutes with a 10 second interval
resource "terracurl_request" "ollama" {
  depends_on = [ aws_instance.ollama ]
  
  name = "ollama"
  url = "http://${aws_instance.ollama.public_ip}"
  method = "GET"

  response_codes = [200]
  max_retry      = 120
  retry_interval = 10
}