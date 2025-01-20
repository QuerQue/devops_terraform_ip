resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = element(["eu-central-1a", "eu-central-1b", "eu-central-1c"], count.index)
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
}

resource "aws_lb_target_group" "lb_tg" {
  name     = "lb-tg-0"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "instance"
}

resource "aws_lb" "app_lb" {
  name               = "app-lb-0"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }
}

resource "aws_launch_template" "ec2_templ" {
  name          = "ec2-templ-0"
  image_id      = "ami-0cdd6d7420844683b"
  instance_type = "t2.micro"

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install nginx -y
              sudo systemctl enable nginx
              sudo systemctl start nginx
              sudo bash -c 'echo "<h1>Hello from $(hostname -f)</h1>" > /usr/share/nginx/html/index.html'
              EOF
  )

  network_interfaces {
    security_groups = [aws_security_group.web_sg.id]
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name                = "web-asg-0"
  max_size            = 4
  min_size            = 2
  desired_capacity    = 2
  vpc_zone_identifier = aws_subnet.public[*].id

  launch_template {
    id      = aws_launch_template.ec2_templ.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.lb_tg.arn]
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "cpu-scale-up"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}

resource "aws_s3_bucket" "web_storage" {
  bucket = "web-app-storage-bucket-0"
}

resource "aws_db_instance" "postgres" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "14"
  instance_class       = "db.t3.micro"
  db_name              = "webdb"
  username             = "admin"
  password             = "password123"
  parameter_group_name = "default.postgres14"
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.web_sg.id]
}
