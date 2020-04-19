# Security Groups for ALB
resource "aws_security_group" "alb-sg" {
  name        = format("%s-%s-ALB", var.environment, var.namespace)
  description = format("allow egress from %s Load Balancer (ALB)", var.environment)
#  vpc_id      = data.aws_vpc.default.id
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = format("%s-%s-ALB", var.environment, var.namespace)
  }
}

# Create a single load balancer for all project services
resource "aws_alb" "project" {
  name                       = format("%s-%s-ALB", var.environment, var.namespace)
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = "300"
  security_groups            = [aws_security_group.alb-sg.id]
#  subnets                    = data.aws_subnet_ids.default.ids
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = false
  enable_http2               = true
  access_logs {
    enabled = true
    bucket = aws_s3_bucket.alb_logs.bucket
    prefix = var.alb_log_path
  }

  tags = {
    Name = format("%s-%s-ALB", var.environment, var.namespace)
  }
}

#target groups
resource "aws_lb_target_group" "project" {
  count = length(var.target_groups)
  name     = format("%s-%s-%s", var.environment, var.namespace, lookup(var.target_groups[count.index], "name"))
  port     = lookup(var.target_groups[count.index], "port")
  protocol = "HTTP"
#  vpc_id   = data.aws_vpc.default.id
  vpc_id   = module.vpc.vpc_id
  health_check {
    path    = lookup(var.target_groups[count.index], "path")
    matcher = lookup(var.target_groups[count.index], "matcher")
  }
}

# s3 bucket for alb logs
resource "aws_s3_bucket" "alb_logs" {
  bucket = format("%s-%s-%s-%s-alb-logs", var.domain, var.aws_region, var.environment, var.namespace)
  acl    = "log-delivery-write"
  lifecycle_rule {
    id      = "log"
    enabled = true
    expiration {
      days = 90
    }
  }
}
data "aws_iam_policy_document" "logs_bucket_policy" {
  statement {
    sid       = "Allow LB to write logs"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_logs.bucket}/${var.alb_log_path}*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::797873946194:root"]
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.alb_logs.bucket
  policy = data.aws_iam_policy_document.logs_bucket_policy.json
}

#==============================================================
# Define listeners
#=============================================================
# listener to redirect all 80 to 443
resource "aws_lb_listener" "http" {
  depends_on        = [aws_alb.project]
  load_balancer_arn = aws_alb.project.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      host        = "#{host}"
      path        = "/#{path}"
      query       = "#{query}"
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# https listener and final default rule to redirect to main domain
resource "aws_lb_listener" "https" {
  depends_on = [aws_lb_target_group.project]
  load_balancer_arn = aws_alb.project.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = var.ssl_arn

  default_action {
    type = "redirect"
    redirect {
      host        = ${var.domain}
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
      path        = "/#{path}"
      query       = "#{query}"
    }
  }
}

# add additional certs to listener
resource "aws_lb_listener_certificate" "project" {
  depends_on = [aws_lb_listener.https]
  for_each = var.ssl_arns
  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = each.value
}

# first listner rule defaults to catch var.domain
resource "aws_lb_listener_rule" "www-default" {
  depends_on = [aws_lb_listener.https, aws_lb_target_group.project]
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.project[0].arn
  }

  condition {
    host_header {
      values = [format("%s", var.domain)]
    }
  }
}

# create listener for all target  groups
resource "aws_lb_listener_rule" "project" {
  depends_on = [aws_lb_listener.https, aws_lb_target_group.project]
  count = length(var.target_groups)
  listener_arn = aws_lb_listener.https.arn
  priority     = lookup(var.target_groups[count.index], "priority")

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.project[count.index].arn
  }

  condition {
    host_header {
      values = lookup(var.target_groups[count.index], "domains")
    }
  }
}
# can also create redirect rules for domains
resource "aws_lb_listener_rule" "default" {
  depends_on = [aws_lb_listener.https]
  listener_arn = aws_lb_listener.https.arn
  priority     = 200
  action {
    type = "redirect"
    redirect {
      host        = format("www.%s", var.domain)
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
      path        = "/#{path}"
      query       = "#{query}"
    }
  }

  condition {
    host_header {
      values = [var.domain]
    }
  }
}
