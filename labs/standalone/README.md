# Azure Standalone Spoke

## Updates
8/5/2024 - Initial release

## Overview
The Terraform code in this repository deploys a small environment that can be used affordably experiment with Azure products in an enterprise-like environment. This environment is built for standalone workloads and includes core infrastructure services such as DNS, network mediation, and secure remote access.

## Architecture
The environment is deployed in a single resource group. 

It uses a stand-alone virtual network. The virtual network is broken into multiple subnets to support common Azure workloads. Each virtual network includes a custom route table (where relevant) and network security group. Subnets for core infrastructure components such as Azure API Management and Azure Application Gateway include required network security group rules and user-defined routes.

Other features include:

1) VNet Flow Logs and traffic analytics to provide for insight into network traffic flows
2) Windows virtual machine provisioned with a variety of tools including Azure Powershell, Azure CLI, and Visual Studio Code
3) Diagnostic logging enabled for all services that support it with logs being sent to a central Log Analytics Workspace
4) Private DNS Zones for commonly used services linked to the workload virtual network
5) Managed identity and Azure Key Vault provisioned for use with application workloads
6) Centralized Azure Key Vault which stores username and password configured on the virtual machine

![lab image](assets/lab-visual.svg)

## Prerequisites
1. You must hold at least the Owner role within each Azure subscription you configure the template to deploy resources to or you must have sufficient delegated permissions to create role assignments.

2. Get the object id of the security principal (user, managed identity, service principal) that will have access to the Azure Key Vault instance. This will be used for the key_vault_admin parameter when running the code. Ensure you are using the most up to date version of az cli.

3. The virtual machines provisioned by this code draw their bootstrapping scripts from this repository.

**az ad user show --id someuser@sometenant.com --query id --output tsv**

4. Enable Network Watcher in the region you plan to deploy the resources using the Azure Portal method described in this link. Do not use the CLI option because the templates expect the Network Watcher resource to be named NetworkWatcher_REGION, such as NetworkWatcher_eastus2. The CLI names the resource watcher_REGION such as watcher_eastus2 which will cause the deployment of the environment to fail.

5. You must have at least Terraform version 1.8.3 installed on your machine.

## Installation
1. Clone the repository.

2. Create a [terraform tfvars file](https://developer.hashicorp.com/terraform/language/values/variables) that includes the variables below. You can also pass these variables at the command line when running terraform apply.

* key_vault_admin - This is the object id you obtained from the prerequiste step 2.

* tags - These are the tags you want associated to the resource. By default two tags will be added in addition to the tags you specify. A createdBy tag will be added to each resource with the objectId of the user who created the resources. A createdTime tag will be added as well indicating the time the resource was created. Example: {environment = "lab", product = "test"}

* location - This is the Azure region you want to deploy the resources to. Example: "eastus"

* address_space_azure - This is the address space you want to use for the lab. The lab requires a large enough block to provide for at least three /16s. Example: "10.0.0.0/8"

* address_space_onpremises - This is the address space for any VPN sites connected to the VPN Gateway. Example: "192.168.0.0/16"

* admin_username - This is the username configured for the administrator account on the virtual machine. This is stored in the central Key Vault for reference.

* admin_password - This is the password configured for the administrator account on the virtual machine. This is stored in the central Key Vault for reference.

* trusted_ip_address - This is the IP address that is granted access access to establish a remote desktop connection to the Windows virtual machine.

3. Run the following command to initialize Terraform.
`terraform init`

4. Run the following command to deploy the resources. This lab deploys several resources at once and can hit Azure ARM REST API limits. It's recommended ot set the parallelism to 5 or lower to mitigate the risks of hitting these API limits and the deployment failing.
`terraform apply -parallelism=5`
