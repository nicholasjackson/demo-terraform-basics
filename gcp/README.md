# Basic Terraform example to create a Virtual Machine in Google Cloud

The purpose of this example is to show some of the more basic features of Terraform:
* Providers
* Resources
* Data blocks
* Variables
* Outputs
* Functions and Interpolation

This example creates a Virtual Machine in Google Cloud and provisions the Open Web UI
using a cloud-init script.

[https://github.com/open-webui/open-webui](https://github.com/open-webui/open-webui)

Open Web UI allows you to run LLMs locally and enables you to build local RAG workflows
for AI applications. You can also use Open Web UI to integrate with OpenAI APIs.

It is acknowledged that the provision of the Open Web UI application using Cloud
Init is not the most optimal way to provision an application with Terraform.
This approach has been taken for simplicity, a more production-ready approach would
be to use Packer to bake a VM with the software installed and then use Terraform to
deploy it. An example for Packer can be found in with the AWS example in this repository.

A full walkthrough explaining this example can be found at the following link.

[https://www.youtube.com/watch?v=Xni8GUcWQ_s](https://www.youtube.com/watch?v=Xni8GUcWQ_s)

## Requirements

* A Google Cloud account and credentials that can be used to deploy resources.
* Optional - The ability to deploy GPU based Virtual Machines
* Optional - Open AI API Key to use with Open Web UI

## Providers Used

* [Google Cloud 5.35.0](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
* [Terracurl 1.2.1](https://registry.terraform.io/providers/devops-rob/terracurl/latest/docs)
* [Random 3.6.2](https://registry.terraform.io/providers/hashicorp/random/latest/docs)

## Resources Created

* 1x Resource Group
* 1x Virtual Machine (Standard_NC4as_T4_v3 or Standard_A2_v2)
* 1x Random Password
* 1x Terracurl Request
* 1x Cloudinit Config
* 1x Virtual Network
* 1x Subnet
* 1x Public IP
* 1x Network Interface


## Variables

The following variables are used in this example:

| Name        | Default               | Description                               |
|-------------|-----------------------|-------------------------------------------|
| **region** | europe-west1-b | The region to deploy the Virtual Machine in | 
| **gpu_enabled** | false | When set to true Terraform will deploy a GPU based Virtual Machine based on a g4dn.xlarge, when false a t3.micro is used |
| **machine** | g2-standard-4, n1-standard-4 | The type of Virtual Machine to deploy, selected dependent on gpu_enabled variable |
| **open_webui_user** | admin@demo.gs | The username to use with Open Web UI |
| **openai_base** | https://api.openai.com/v1 | The base URL for the Open AI API
| **openai_key** | "" | The Open AI API Key to use with Open Web UI |
| **ssh_pub_key** | "" | The SSH Public Key to use with the Virtual Machine |


## Authentication

### Google Cloud Credentials

To run this example you will need a GCP account and valid credentials that 
can be used to deploy resources. A GCP Free Trial account can be used to create the CPU example shown in this
demo. You can sign up for a GCP account at the following link.

[https://cloud.google.com/free?hl=en](https://cloud.google.com/free?hl=en)

Once you have created an account you need to create ARM credentials that Terraform
can use to create resources. The process for creating the credentials is detailed in
the walk through video:

[https://youtu.be/Xni8GUcWQ_s?si=4b6Ht_uaqWJ6vhZ6&t=230](https://youtu.be/Xni8GUcWQ_s?si=4b6Ht_uaqWJ6vhZ6&t=230)

It is incredibly important to ensure that your credentials stay secret. Terraform
can read credentials from environment variables, so rather than hardcoding them in
the configuration you need to set them in your environment. An example of how to
set the environment variables is shown below. You would need to replace the `xxxx`
values with your own credentials, and the region with the region you want to deploy.

```shell
export ARM_CLIENT_ID="xxxx-xxxx-xxxx-xxxx-xxxx"
export ARM_SUBSCRIPTION_ID="xxxx-xxxx-xxxx-xxxx-xxxx"
export ARM_TENANT_ID="xxxx-xxxx-xxxx-xxxx-xxxx"
export ARM_CLIENT_SECRET="xxxx-xxxx-xxxx-xxxx-xxxx"
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

# set the Azure environment variables, this loads the values from 1Password item "Terraform Basics"
# selecting the item with a field the same as the environment variable name
export ARM_CLIENT_ID="$(${command} item get "Terraform Basics" --fields "ARM_CLIENT_ID")"
export ARM_SUBSCRIPTION_ID="$(${command} item get "Terraform Basics" --fields "ARM_SUBSCRIPTION_ID")"
export ARM_TENANT_ID="$(${command} item get "Terraform Basics" --fields "ARM_TENANT_ID")"
export ARM_CLIENT_SECRET="$(${command} item get "Terraform Basics" --fields "ARM_CLIENT_SECRET")"

# prefixing the TF_VAR_ environment variables allows Terraform to use them as variables
export TF_VAR_openai_base="https://api.openai.com/v1"
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