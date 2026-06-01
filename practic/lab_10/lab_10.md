# 🛠️ Lab 10: Provisioners & Connections (The Danger Zone)

## Concepts to Practice
* Local execution (`local-exec`)
* Remote script execution (`remote-exec`)
* Network authentication (`connection` blocks)
* Lifecycle hooks (`when = destroy`)
* Error handling (`on_failure = continue`)

---

## Objective
Deploy an Ubuntu EC2 instance and interact with it outside of Terraform's standard state management. You will use `local-exec` to write the server's IP address to a local text file, and `remote-exec` to SSH into the server and install Nginx. Finally, you will test a destroy-time provisioner.

**⚠️ Prerequisite:** You MUST have your AWS-generated `.pem` Private Key saved in your project directory to successfully run this lab.

---

## Terraform Code (`lab_10.tf`)

```hcl
provider "aws" {
  region = "us-east-1"
}

# 0. ADD THE SECURITY GROUP
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_lab10"
  description = "Allow SSH inbound traffic"

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
```

---

## Execution & Testing Steps

#### Phase 1: Deployment & Authentication
1. Double-check line 10 (`key_name`) to ensure it perfectly matches the name of the key pair in your AWS Console. 
2. Run `terraform init` and `terraform apply -auto-approve`.
3. Watch your terminal closely. You will see Terraform actively connecting over SSH using your `.pem` file and printing the standard Ubuntu `apt-get` logs directly to your screen.

#### Phase 2: Verifying Local Execution
1. Look inside your folder. You will see a brand new file named `server_info.txt` that Terraform created locally.
2. Open it. It should contain a message with the public IP of your new EC2 instance.

#### Phase 3: Verifying Remote Execution
1. Copy the public IP address from `server_info.txt`.
2. Open your web browser and paste the IP into the address bar. 
3. You should see the default **"Welcome to nginx!"** landing page. Terraform successfully reached inside the server and configured it.

#### Phase 4: The Destroy Trigger
1. Run `terraform destroy -auto-approve`.
2. As soon as the destroy command starts, Terraform will trigger the `when = destroy` provisioner.
3. Open `server_info.txt` one last time. You will see the final death message appended to the bottom of the file!