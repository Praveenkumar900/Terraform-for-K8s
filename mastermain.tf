# Define the AWS provider configuration.
provider "aws" {
  region = "us-east-1"  # Replace with your desired AWS region.
}

variable "cidr" {
  default = "10.0.0.0/16"
}

resource "aws_key_pair" "example" {
  key_name   = "terraform-demo-abhi"  # Replace with your desired key name
  public_key = file("/home/ubuntu/.ssh/id_rsa.pub")  # Replace with the path to your public key file
}

resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_security_group" "webSg" {
  name   = "web"
  vpc_id = aws_vpc.myvpc.id

ingress {
  description = "Allow access to various Kubernetes services"
  from_port   = 22  # SSH access
  to_port     = 22
  protocol   = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
  # Kubernetes API server
  from_port   = 6443
  to_port     = 6443
  protocol   = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
ingress {
  # etcd server client API
  from_port   = 2379
  to_port     = 2380
  protocol   = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
ingress {
  # Kubelet API
  from_port   = 10250
  to_port     = 10250
  protocol   = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
ingress {
  # kube-scheduler
  from_port   = 10259
  to_port     = 10259
  protocol   = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
ingress {
  # kube-controller-manager
  from_port   = 10257
  to_port     = 10257
  protocol   = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
ingress {
  # Flannel VXLAN communication
  from_port   = 8472
  to_port     = 8472
  protocol   = "udp"
  cidr_blocks = ["0.0.0.0/0"]
}

  tags = {
    Name = "Web-sg"
  }
}

resource "aws_instance" "server" {
  ami                    = "ami-0261755bbcb8c4a84"
  instance_type          = "t2.medium"
  key_name      = aws_key_pair.example.key_name
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.sub1.id

  connection {
    type        = "ssh"
    user        = "ubuntu"  # Replace with the appropriate username for your EC2 instance
    private_key = file("/home/ubuntu/.ssh/id_rsa")  # Replace with the path to your private key
    host        = self.public_ip
  }

  # File provisioner to copy a file from local to the remote EC2 instance
  #provisioner "file" {
   # source      = "app.py"  # Replace with the path to your local file
    #destination = "/home/ubuntu/app.py"  # Replace with the path on the remote instance
  #}

  provisioner "remote-exec" {
    inline = [
      "cd /home/ubuntu",
      "sudo hostnamectl set-hostname master",
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https gnupg2",
      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
      "echo “deb https://apt.kubernetes.io/ kubernetes-xenial main” | sudo tee -a /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update",
      "sudo apt-get install -y kubectl kubeadm kubelet kubernetes-cni docker.io",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker $USER",
      "newgrp docker",
      "cat << EOF | sudo tee /etc/sysctl.d/k8s.conf",
      "net.bridge.bridge-nf-call-ip6tables = 1",
      "net.bridge.bridge-nf-call-iptables = 1",
      "EOF",
      "sudo sysctl --system",

      #Setting Up Master Node for Kubernetes
      "sudo kubeadm config images pull",
      "echo ‘{“exec-opts”: [“native.cgroupdriver=systemd”]}’ | sudo tee /etc/docker/daemon.json",
      "sudo systemctl daemon-reload",
      "sudo systemctl restart docker",
      "sudo systemctl restart kubelet",

      #sudo kubeadm init — apiserver-advertise-address=172.31.21.161 — pod-network-cidr=10.244.0.0/16 # Use your master node’s private IP
      # Join the worker Nodes to master using kubeadm join

      #set up local `kubeconfig` on master node
      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      "kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml",

      #Kubectl get nodes
    ]
  }
}
