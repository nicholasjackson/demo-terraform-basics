data "aws_ami" "debian" {
  most_recent = true
  filter {
    name   = "name"
    values = [var.ami_name]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = var.ami_owners 
}

# Create a random password for the web UI
resource "random_password" "password" {
  length           = 16
  special          = false
}

resource "aws_vpc" "openwebui" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "subnet" {
  cidr_block        = cidrsubnet(aws_vpc.openwebui.cidr_block, 4, 1)
  vpc_id            = aws_vpc.openwebui.id
  availability_zone = "${var.region}a"
}

resource "aws_internet_gateway" "openwebui" {
  vpc_id = aws_vpc.openwebui.id
}

resource "aws_route_table" "openwebui" {
  vpc_id = aws_vpc.openwebui.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.openwebui.id
  }
}

resource "aws_route_table_association" "openwebui" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.openwebui.id
}

resource "aws_security_group" "ssh" {
  name = "allow-all"

  vpc_id = aws_vpc.openwebui.id

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

  vpc_id = aws_vpc.openwebui.id

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

resource "aws_key_pair" "openwebui" {
  key_name   = "openwebui"
  public_key = file(var.ssh_pub_key)
}

resource "aws_spot_instance_request" "openwebui" {
  ami                         = var.custom_ami != "" ? var.custom_ami : data.aws_ami.debian.id
  instance_type               = var.gpu_enabled ? var.machine.gpu.type : var.machine.cpu.type
  key_name                    = resource.aws_key_pair.openwebui.key_name
  wait_for_fulfillment        = true
  associate_public_ip_address = true

  security_groups = [
    "${aws_security_group.ssh.id}",
    "${aws_security_group.http.id}"
  ]

  subnet_id = aws_subnet.subnet.id

  user_data_base64 = base64encode(templatefile("${path.module}/${var.provision_script}",
    {
      gpu_enabled         = var.gpu_enabled
      open_webui_user     = var.open_webui_user
      open_webui_password = random_password.password.result
      openai_base         = var.openai_base
      openai_key          = var.openai_key
  }))

  root_block_device {
    volume_size = 60
  }
}

# Create a terracurl request to check if the web server is up and running
# Wait a max of 20 minutes with a 10 second interval
resource "terracurl_request" "openwebui" {
  name   = "openwebui"
  url    = "http://${aws_spot_instance_request.openwebui.public_ip}"
  method = "GET"

  response_codes = [200]
  max_retry      = 120
  retry_interval = 10
}
