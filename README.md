Project

Polkadot Fullnode Deployment and Update Automation


Description

This project automates the deployment of two Ubuntu instances on AWS using Terraform. The instances each have some block storage assigned, a pubic IP and a relevant security group for the purpose of interacting on the polkadot network. Once the instances are deployed ansible will install and update Polkadot to the latest code version.


Prerequisites

AWS Account: 
https://aws.amazon.com/resources/create-account/

Terraform: To install Terraform on your system please refer to the documentation here:
https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

Ansible: To install Ansible on your system please refer to the documentation here:
https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html

AWS Cli: To install AWS cli on your system please refer to the documentation here:
https://aws.amazon.com/cli/


Usage

Clone the repo:
git clone https://github.com/kookin/polkarob

Create keypair in AWS GUI:
In the EC2 Dashboard, click on "Key Pairs" in the left navigation pane.
Click the "Create Key Pair" button.
Once the key pair is created, the private key file will be automatically downloaded to your computer. Ensure that you keep this file secure.

Create keypair with AWSCLI: 
aws ec2 create-key-pair --key-name YourKeyName --query 'KeyMaterial' --output text > YourKeyName.pem

Make sure to set appropriate permissions on the private key file (chmod 400 YourKeyName.pem) to ensure it's secure.

Edit polkarob with your key info:
Open 'polkarob.tf'.

Replace the followng values:

Note: To find the vpc id for the default vpc use this aws cli command:
aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text

locals {
  ssh_user ="ubuntu"
  key_name ="polka"   <= REPLACE
  private_key_path ="~/Desktop/polka.cer"    <= REPLACE
  vpc_id = "vpc-06f39ba13d867f125"    //default vpc     <= REPLACE
}

To start running the automation you need to initialize terraform:
terraform init

Optionally run terraform plan to create and view the execution plan:
terraform plan

To run the automation use:
Terraform apply

This will run through the terraform code and execute the ansible playbook(s) once the servers are online in AWS.



Contact

rfrantl@icloud.com