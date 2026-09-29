provider "aws" {
  region = "us-east-1"
}

# 0. ADD THE SECURITY GROUP
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_lab10"
  description = "Allow SSH inbound traffic and http traffic"

  # Allow incoming SSH from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ADD THIS: The door for your Web Browser (HTTP)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Allow the server to download packages (like Nginx) from the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_server" {
  ami           = "ami-0c7217cdde317cfec" # Standard Ubuntu AMI
  instance_type = "t3.micro"

  # REPLACE THIS with the exact name of your key pair from the AWS Console
  key_name = "terraform"

  # 1. THE CONNECTION BLOCK (Required for remote-exec)
  connection {
    type = "ssh"
    user = "ubuntu"
    # Absolute path to the .pem file downloaded from AWS
    private_key = file("../terraform.pem")
    host        = self.public_ip
  }

  # 2. ATTACH THE SECURITY GROUP TO THE INSTANCE
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  # 3. REMOTE-EXEC: Runs directly on the AWS Server
  provisioner "remote-exec" {
    # If the Nginx install fails, print a warning but do NOT taint the resource
    on_failure = continue

    inline = [
      "echo 'Waiting for server to fully boot...'",
      "sudo apt-get update -y",
      "sudo apt-get install -y nginx",
      "sudo systemctl start nginx"
    ]
  }

  # 4. LOCAL-EXEC: Runs on your local laptop
  provisioner "local-exec" {
    command = "echo 'The server IP is ${self.public_ip}' > server_info.txt"
  }

  # 5. DESTROY-TIME PROVISIONER: Runs right before deletion
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Server ${self.public_ip} has been destroyed!' >> server_info.txt"
  }
}