terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.46.0"
    }
  }
}

# configuração do provedor Azure
provider "azurerm" {
  features {}
}

# criação de um grupo de recursos no Azure
resource "azurerm_resource_group" "example" {
  name     = "rg-wordpress"
  location = "West Europe"
}

# criação de uma rede virtual
resource "azurerm_virtual_network" "example" {
  name                = "vnet-wordpress"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# criação de uma sub-rede
resource "azurerm_subnet" "example" {
  name                 = "subnet-wordpress"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

# criação de um IP público
resource "azurerm_public_ip" "example" {
  name                = "public-ip-wordpress"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# criação de uma interface de rede
resource "azurerm_network_interface" "example" {
  name                = "nic-wordpress"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id         = azurerm_public_ip.example.id
  }
}

# criação de um grupo de segurança de rede. SSH/HTTP/MYSQL
resource "azurerm_network_security_group" "example" {
  name                = "nsg-wordpress"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-MySQL"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# associação do grupo de segurança à interface de rede
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

# criação de uma máquina virtual Linux
resource "azurerm_linux_virtual_machine" "example" {
  name                = "vm-wordpress"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
   
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  custom_data = base64encode(<<-EOT
    #!/bin/bash

    # Instalar o Docker
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io

    # Adicionar o usuário ao grupo docker
    usermod -aG docker adminuser

    # Executar container do MySQL
    docker run --name mysql-container -e MYSQL_ROOT_PASSWORD=YourRootPassword -d -p 3306:3306 mysql:latest

    # Executar container do WordPress
    docker run -d -p 80:80 --name wordpress --link mysql-container:mysql wordpress
  EOT
  )

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = {
    environment = "development"
  }
}

output "public_ip" {
  value = azurerm_public_ip.example.ip_address
}

# script para remover a chave do host conhecido
resource "null_resource" "ssh_key_removal" {
  provisioner "local-exec" {
    command = <<EOT
      ssh-keygen -R ${azurerm_public_ip.example.ip_address}
    EOT
  }

  depends_on = [azurerm_linux_virtual_machine.example]
}

# output com detalhes de conexão do banco de dados
output "db_connection_details" {
  value = {
    host     = azurerm_public_ip.example.ip_address
    port     = 3306
    username = "root"
    password = "GAud4mZby8F3SD6P"
  }
}


