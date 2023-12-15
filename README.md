# Project: Polkadot Fullnode Deployment and Update Automation

## Description

This project automates the deployment of two Ubuntu 22.04 instances on AWS using Terraform. The instances are sized 'c6i.4xlarge' and each have a public IP, and a relevant security group for the purpose of interacting on the Polkadot network. Once the instances are deployed, Ansible will install and update Polkadot to a user specified code version and start each node to participate on the Polkadot network.

## Prerequisites

- **AWS Account:** [Create an AWS Account](https://aws.amazon.com/resources/create-account/)
- **Terraform:** Install Terraform on your system. Refer to the documentation [here](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
- **Ansible:** Install Ansible on your system. Refer to the documentation [here](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html).
- **AWS CLI:** Install AWS CLI on your system. Refer to the documentation [here](https://aws.amazon.com/cli/).


## Usage

    1. Clone the repo:
      git clone https://github.com/kookin/polkarob

    2. Create keypair in AWS GUI:
        In the EC2 Dashboard, click on "Key Pairs" in the left navigation pane.
        Click the "Create Key Pair" button.
        Once the key pair is created, the private key file will be automatically downloaded to your computer. Ensure that you keep this file secure.

    3. Create keypair with AWSCLI: 
        aws ec2 create-key-pair --key-name YourKeyName --query 'KeyMaterial' --output text > YourKeyName.pem

    4. Make sure to set appropriate permissions on the private key file (chmod 400 YourKeyName.pem) to ensure it's secure.

    5. Edit polkarob with your key info:
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

    6. Specify the Polkadot SDK version to be deployed (default = v1.0.0) 
        Open 'polka.yaml'
        At the beginning of the file find the line that reads 'latest_version: "1.0.0"' 
        Change the version if required, e.g. 'latest_version: "1.2.0"' 

    7. To start running the automation you need to initialize terraform:
        terraform init

    8. Optionally run terraform plan to create and view the execution plan:
        terraform plan

    9. To run the automation use:
        terraform apply

    This will run through the terraform code and execute the ansible playbook(s) once the servers are online in AWS.


Contact

For questions/queries, please contact: 
rfrantl@icloud.com