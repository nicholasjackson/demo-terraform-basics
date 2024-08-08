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

resource "aws_vpc" "open_web_ui" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "subnet" {
  cidr_block        = cidrsubnet(aws_vpc.open_web_ui.cidr_block, 2, 1)
  vpc_id            = aws_vpc.open_web_ui.id
  availability_zone = "eu-central-1a"
}

resource "aws_internet_gateway" "open_web_ui" {
  vpc_id = aws_vpc.open_web_ui.id
}

resource "aws_route_table" "open_web_ui" {
  vpc_id = aws_vpc.open_web_ui.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.open_web_ui.id
  }
}

resource "aws_route_table_association" "open_web_ui" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.open_web_ui.id
}

resource "aws_security_group" "ssh" {
  name = "allow-all"

  vpc_id = aws_vpc.open_web_ui.id

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

resource "aws_key_pair" "open_web_ui" {
  key_name   = "open_web_ui"
  public_key = file("/tmp/id_rsa.pub")
}

resource "aws_security_group" "http" {
  name = "allow-all-http"

  vpc_id = aws_vpc.open_web_ui.id

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

resource "aws_spot_instance_request" "cheap_worker" {
  ami           = data.aws_ami.debian.id
  instance_type = "t3.micro"
  wait_for_fulfillment        = true
  associate_public_ip_address = true

  key_name                    = resource.aws_key_pair.open_web_ui.key_name

  vpc_security_group_ids = [
    aws_security_group.ssh.id,
    aws_security_group.http.id
  ]

  subnet_id = aws_subnet.subnet.id

  user_data_base64 = base64encode(templatefile("./scripts/provision_basic.sh", 
  {
    open_webui_user = var.open_webui_user,
    openai_base     = var.openai_base,
    openai_key      = var.openai_key
  }))
}

# Create a terracurl request to check if the web server is up and running
# Wait a max of 20 minutes with a 10 second interval
resource "terracurl_request" "open_web_ui" {
  name   = "open_web_ui"
  url    = "http://${aws_spot_instance_request.cheap_worker.public_ip}"
  method = "GET"

  response_codes = [200]
  max_retry      = 120
  retry_interval = 10
}