provider "azurerm" {
    subscription_id = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    client_id       = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    client_secret   = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    tenant_id       = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

resource "azurerm_resource_group" "dvsmresourcegroup" {
    name     = "dvsmResourceGroup"
    location = "East US"

    tags {
        environment = "CNTK DVSM Workshop"
    }
}

resource "azurerm_virtual_network" "dvsmnetwork" {
    name                = "dvsmVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "East US"
    resource_group_name = "${azurerm_resource_group.dvsmresourcegroup.name}"

    tags {
        environment = "CNTK DVSM Demo "
    }
}

resource "azurerm_subnet" "dvsmsubnet" {
    name                 = "dvsmSubnet"
    resource_group_name  = "${azurerm_resource_group.dvsmresourcegroup.name}"
    virtual_network_name = "${azurerm_virtual_network.dvsmnetwork.name}"
    address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "dvsmpublicip" {
    name                         = "dvsmPublicIP"
    location                     = "East US"
    resource_group_name          = "${azurerm_resource_group.dvsmresourcegroup.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "CNTK DVSM Workshop"
    }
}

resource "azurerm_network_security_group" "dvsmpublicipnsg" {
    name                = "dvsmNetworkSecurityGroup"
    location            = "East US"
    resource_group_name = "${azurerm_resource_group.dvsmresourcegroup.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "CNTK DVSM Workshop"
    }
}

resource "azurerm_network_interface" "dvsmnic" {
    name                = "dvsmNIC"
    location            = "East US"
    resource_group_name = "${azurerm_resource_group.dvsmresroucegroup.name}"

    ip_configuration {
        name                          = "dvsmNicConfiguration"
        subnet_id                     = "${azurerm_subnet.dvsmsubnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.dvsmpublicip.id}"
    }

    tags {
        environment = "CNTK DVSM Workshop"
    }
}

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.dvsmresourcegroup.name}"
    }

    byte_length = 8
}

resource "azurerm_storage_account" "mystorageaccount" {
    name                = "diag${random_id.randomId.hex}"
    resource_group_name = "${azurerm_resource_group.dvsmresourcegroup.name}"
    location            = "East US"
    account_type        = "Standard_LRS"

    tags {
        environment = "CNTK DVSM Workshop"
    }
}

resource "azurerm_virtual_machine" "dvsmvm" {
    name                  = "dvsmVM"
    location              = "East US"
    resource_group_name   = "${azurerm_resource_group.dvsmresroucegroup.name}"
    network_interface_ids = ["${azurerm_network_interface.dvsmnic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "dvsmOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "microsoft-ads"
        offer     = "linux-data-science-vm-ubuntu"
        sku       = "linuxdsvmubuntu"
        version   = "latest"
    }

    os_profile {
        computer_name  = "dvsm"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3Nz{snip}hwhqT9h"
        }
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = "${azurerm_storage_account.dvsmstorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "CNTK DVSM Workshop"
    }
}
