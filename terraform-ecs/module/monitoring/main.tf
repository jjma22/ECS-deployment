resource "aws_iam_policy" "policy-test-terraform" {
  name        = "terraformtest"
  path        = "/"
  description = "My test policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "elasticloadbalancing:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:Describe*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "autoscaling:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      }

    ]
  })
}
resource "aws_iam_role" "monitoring_role" {
  name = "monitoring_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

}

resource "aws_iam_policy_attachment" "example_attachment" {
  name       = "example-policy-attachment"
  roles      = [aws_iam_role.monitoring_role.name]
  policy_arn = aws_iam_policy.policy-test-terraform.arn
}

resource "aws_iam_instance_profile" "monitoring_profile" {
  name = "ec2-monitoring"
  role = aws_iam_role.monitoring_role.name
}



resource "aws_security_group" "monitoring_sg" {
  name        = "notes-moniroing-sg-ecs"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 9779
    to_port     = 9779
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
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

module "ec2_instance" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  ami                    = "ami-0eb260c4d5475b901"
  name                   = "single-instance"
  iam_instance_profile   = aws_iam_instance_profile.monitoring_profile.name
  instance_type          = "t2.micro"
  key_name               = "notes_keypair"
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]
  subnet_id              = var.public_subnets[0]
  user_data              = <<EOF
#!/bin/bash
sudo useradd --no-create-home prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo wget https://github.com/prometheus/prometheus/releases/download/v2.37.0/prometheus-2.37.0.linux-amd64.tar.gz
sudo tar xvfz prometheus-2.37.0.linux-amd64.tar.gz
sudo cp prometheus-2.37.0.linux-amd64/prometheus /usr/local/bin
sudo cp prometheus-2.37.0.linux-amd64/promtool /usr/local/bin/
sudo cp -r prometheus-2.37.0.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-2.37.0.linux-amd64/console_libraries /etc/prometheus
sudo cp prometheus-2.37.0.linux-amd64/promtool /usr/local/bin/
sudo rm -rf prometheus-2.37.0.linux-amd64.tar.gz prometheus-2.37.0.linux-amd64
sudo touch /etc/prometheus/prometheus.yml
sudo tee /etc/prometheus/prometheus.yml <<EOF_1
global:
  scrape_interval: 15s
  external_labels:
    monitor: 'prometheus'

scrape_configs:
  - job_name: 'instances'
    ec2_sd_configs:
      - region: 'eu-west-2'  
        port: 9779
        filters: 
          - name: 'vpc-id'
            values:
              - ${var.vpc_id}

EOF_1
sudo touch /etc/systemd/system/prometheus.service
sudo tee /etc/systemd/system/prometheus.service <<EOF_2
global:
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries
[Install]
WantedBy=multi-user.target
EOF_2
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
sudo chown -R prometheus:prometheus /var/lib/prometheus
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo service prometheus restart
sudo service prometheus status
EOF






  tags = {
    Terraform = "true"
  }
}
