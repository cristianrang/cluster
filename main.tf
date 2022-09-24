provider "aws" {                                          #Provider es el proveedor de servicios al que conectará terraformm
  access_key = var.AWS_ACCESS_KEY                      #Llave de acceso de aws
  secret_key = var.AWS_SECRET_ACCESS_KEY  #Llave secreta de aws para otorgar acceso a terraform para manipular la cuentaecho 
  region     = "us-east-1"                                #region en la cual se encuentra la cuenta para crear instancias
}

resource "aws_instance" "Docker-Swarm" {
  instance_type          = "t2.micro"
  count = 4
  ami                    = "ami-08d4ac5b634553e16"
  tags = {
    "Name" = "Node-${count.index}"
  }
  key_name               = "MRSI_PCNV"
  user_data              = filebase64("${path.module}/scripts/docker.sh") #Instrucción para correr el archivo docker.sh 
  vpc_security_group_ids = [aws_security_group.DockerWebSG.id]
}

resource "aws_security_group" "DockerWebSG" { #Vamos a crear un grupo de seguridad
  name = "sg_reglas_firewall_docker_swarm"
  ingress {                     #Reglas de firewall de entrada
    cidr_blocks = ["0.0.0.0/0"] #Se aplicará a todas las direcciones
    description = "SG HTTP"     #Descripción
    from_port   = 80            #Del puerto
    to_port     = 80            #Al puerto
    protocol    = "tcp"         #Protocolo
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"] #Se aplicará a todas las direcciones
    description = "SG HTTPS"    #Descripción
    from_port   = 443           #Del puerto
    to_port     = 443           #Al puerto
    protocol    = "tcp"         #Protocolo
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"] #Solo puede entrar esta IP
    description = "SG SSH"               #Descripción
    from_port   = 22                     #Del puerto
    to_port     = 22                     #Al puerto
    protocol    = "tcp"                  #Protocolo
  }
  ingress {
    cidr_blocks = ["172.31.85.220/32","172.31.88.34/32", "172.31.84.166/32", "172.31.82.132/32"] #Solo puede entrar esta IP
    description = "SG Docker Swarm"               #Descripción
    from_port   = 2377                     #Del puerto
    to_port     = 2377                     #Al puerto
    protocol    = "tcp"                  #Protocolo
  }
  ingress {                     #Reglas de firewall de entrada
    cidr_blocks = ["0.0.0.0/0"] #Se aplicará a todas las direcciones
    description = "SG HTTP Visualizer"     #Descripción
    from_port   = 8080            #Del puerto
    to_port     = 8080            #Al puerto
    protocol    = "tcp"         #Protocolo
  }
  egress {                                  #Reglas de firewall de salida
    cidr_blocks = ["0.0.0.0/0"]             #Se aplicará a todas las direcciones
    description = "SG All Traffic Outbound" #Descripción
    from_port   = 0                         #Del puerto
    to_port     = 0                         #Al puerto
    protocol    = "-1"                      #Protocolo sin restricción
  }
}

#Salida de ip publica
output "public_ip" {
  value = join(",", aws_instance.Docker-Swarm.*.public_ip)
}