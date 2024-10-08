# Terraform example to create a Virtual Machine on AWS and provision Open Web UI

The purpose of this example is to show some of the more basic features of Terraform:
* Providers
* Resources
* Data blocks
* Variables
* Outputs
* Functions and Interpolation

This example creates a Virtual Machine in AWS and provisions the Open Web UI
using a cloud-init script.

[https://github.com/open-webui/open-webui](https://github.com/open-webui/open-webui)

Open Web UI allows you to run LLMs locally and enables you to build local RAG workflows
for AI applications. You can also use Open Web UI to integrate with OpenAI APIs.

It is acknowledged that the provision of the Open Web UI application using Cloud
Init is not the most optimal way to provision an application with Terraform.
This approach has been taken for simplicity, a more production-ready approach would
be to use Packer to bake a VM with the software installed and then use Terraform to
deploy it. An example for Packer can be found in this repository.

A full walkthrough explaining this example can be found at the following link.

[https://www.youtube.com/watch?v=rsct-JvJmKs](https://www.youtube.com/watch?v=rsct-JvJmKs)

## Requirements

* An AWS account and IAM Credentials that can be used to deploy resources.
* Optional - The ability to deploy GPU based Virtual Machines
* Optional - Open AI API Key to use with Open Web UI

## Providers Used
* [AWS 5.59.0](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
* [Terracurl 1.2.1](https://registry.terraform.io/providers/devops-rob/terracurl/latest/docs)
* [Random 3.6.2](https://registry.terraform.io/providers/hashicorp/random/latest/docs)

## Resources Created

* 1x VPC
* 1x Subnet
* 1x Internet Gateway
* 1x Routing Table
* 2x Security Groups (ssh, http)
* 1x Virtual Machine (t3.micro or g4dn.xlarge)
* 1x Random Password
* 1x Terracurl Request

## Variables

The following variables are used in this example:

| Name        | Default               | Description                               |
|-------------|-----------------------|-------------------------------------------|
| **gpu_enabled** | false | When set to true Terraform will deploy a GPU based Virtual Machine based on a g4dn.xlarge, when false a t3.micro is used |
| **machine** | t3.micro, g4dn.xlarge | The type of Virtual Machine to deploy, selected dependent on gpu_enabled variable |
| **ami_name** | debian-11-amd64-* | The name of the AMI to use for the Virtual Machine | 
| **ami_owner** | 136693071363 | The owner of the AMI to use for the Virtual Machine, default: debian | 
| **open_webui_user** | admin@demo.gs | The username to use with Open Web UI |
| **openai_base** | https://api.openai.com/v1 | The base URL for the Open AI API
| **openai_key** | "" | The Open AI API Key to use with Open Web UI |
| **ssh_pub_key** | "" | The SSH Public Key to use with the Virtual Machine |


## Authentication

### AWS IAM

To run this example you will need an AWS Account and a valid AWS access key and 
secret. An AWS Free Tier account can be used to create the CPU example shown in this
demo. You can sign up for an AWS account at the following link.

[https://aws.amazon.com/free](https://aws.amazon.com/free)

Once you have created an account you need to create an IAM user that Terraform
can use to create resources. The process for creating an IAM user is detailed in
the walk through video:

[https://youtu.be/rsct-JvJmKs?si=N8VN28bcvok29YIt&t=239](https://youtu.be/rsct-JvJmKs?si=N8VN28bcvok29YIt&t=239)

It is incredibly important to ensure that your credentials stay secret. Terraform
can read credentials from environment variables, so rather than hardcoding them in
the configuration you need to set them in your environment. An example of how to
set the environment variables is shown below. You would need to replace the `xxxx`
values with your own credentials, and the region with the region you want to deploy.

```shell, 
export AWS_ACCESS_KEY_ID="xxxx-xxxx-xxxx-xxxx"
export AWS_SECRET_ACCESS_KEY="xxxx-xxxx-xxxx-xxxx"
export AWS_REGION="eu-west-1"
```

An alternative approach is to use 1Password, you can use the 1Password CLI to populate
the environment variables rather than hard code them in your bash profile or in a environment
script. The following script shows how  you can set environment variables using the 
`op` CLI. This script can then be safely sourced from your bash profile or can be dynamically
loaded using a tool like `direnv`.

```shell
command=op

if ! [ -x "$(command -v op)" ]; then
  # if the op command is not present, assume we are using WSL or Windows bash
	command="op.exe"
fi

# set the AWS environment variables, this loads the values from 1Password item "Terraform Basics"
# selecting the item with a field the same as the environment variable name
export AWS_ACCESS_KEY_ID="$(${command} item get "Terraform Basics" --fields "AWS_ACCESS_KEY_ID")"
export AWS_SECRET_ACCESS_KEY="$(${command} item get "Terraform Basics" --fields "AWS_SECRET_ACCESS_KEY")"
export AWS_REGION="$(${command} item get "Terraform Basics" --fields "AWS_REGION")"

# prefixing the TF_VAR_ environment variables allows Terraform to use them as variables
export TF_VAR_openai_key="$(${command} item get "Terraform Basics" --fields "Open Ai API Key")"
```

### Open AI API

When using the small CPU instance of Open Web UI it is not possible to run a local LLM
as the machine does not have a GPU and has limited CPU and memory. As a replacement
it is possible to configure Open Web UI to send requests to an OpenAI compatible
API.

To use this feature you need an account with a service such as OpenAI and sufficient
credits to use the integration.

[https://openai.com/api/pricing/](https://openai.com/api/pricing/)

To use this integration obtain your API key and set the following environment
variables.

```shell
# openai_base is only needed if not using the default Open AI API url
export TF_VAR_openai_base="https://api.openai.com/v1"
export TF_VAR_openai_key="your key"
```

## Running the Example

To run the example you need to have Terraform installed on your machine. The
Terraform installation instructions can be found at the following link:

[https://learn.hashicorp.com/tutorials/terraform/install-cli](https://learn.hashicorp.com/tutorials/terraform/install-cli)

Once you have installed Terraform and have the AWS credentials set in your environment
you can run the following commands to create the VM.

```shell
terraform init
terraform apply

        ]
      + retry_interval         = 10
      + status_code            = (known after apply)
      + timeout                = 10
      + url                    = (known after apply)
    }

Plan: 11 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + password  = (sensitive value)
  + public_ip = (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.
```

The `terraform apply` command will prompt you to confirm the creation of the resources
before proceeding. If you want to skip this prompt you can use the `-auto-approve` flag.

```shell
terraform apply -auto-approve
```

Depending on the type of Virtual Machine you are deploying the creation process can
take from a few minutes for a CPU instance to 10-15 minutes for a GPU instance.
GPU instances require the installation of the Nvidia drivers and container toolkit
which can take some time.

```
Apply complete! Resources: 11 added, 0 changed, 0 destroyed.

Outputs:

password = <sensitive>
public_ip = "3.66.30.138"
```

### Accessing the Virtual Machine

Once  the Virtual Machine has been created you can access it using the public IP
and the SSH key you provided in the `ssh_pub_key` variable.

For convenience you can use the `terraform output` command in a subshell to get the
public IP address as part of the ssh command.

```shell
ssh admin@(terraform output --raw public_ip)
```

If you run the command `sudo docker ps`, you should see the container running 
the Open Web UI application.

```shell
admin@ip-10-1-0-50:~$ sudo docker ps
CONTAINER ID   IMAGE                                       COMMAND           CREATED         STATUS                   PORTS                                   NAMES
CONTAINER ID   IMAGE                                       COMMAND           CREATED         STATUS                   PORTS                                   NAMES
f7d07f08d101   ghcr.io/open-webui/open-webui:open_web_ui   "bash start.sh"   8 minutes ago   Up 8 minutes (healthy)   0.0.0.0:80->8080/tcp, :::80->8080/tcp   open_web_ui.service
```

### Accessing the Web UI

To access the Web UI you can use the public IP address of the Virtual Machine and
open this in your web browser.

The ip address can be found using the `terraform output` command.

```shell
terraform output public_ip
"3.66.30.138"
```

Open a web browser and navigate to the public IP address of the Virtual Machine.
You should see the login screen for the Open Web UI application.

![Open Web UI Login](/images/open_webui_login.png)

The default username is `admin@demo.gs` or the value you set in the `open_webui_user`
variable. The password is the value output by the `terraform output` command.

```shell
terraform output password
"l3)Uckv=B1C5#d{A"
```

## Cleaning Up

To remove any resources created by Terraform you can use the `terraform destroy`
command. This will remove all the resources created by the configuration.

```shell
terraform destroy
```