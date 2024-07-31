# Basic Terraform example to create a Virtual Machine on AWS

The purpose of this example is to show some of the more basic features of Terraform:
* Providers
* Resources
* Data blocks
* Variables
* Outputs
* Functions and Interpollation

This example creates a Virtual Machine in AWS and provisions the Open Web UI
using a cloud init script.

[https://github.com/open-webui/open-webui](https://github.com/open-webui/open-webui)

Open Web UI allows you to run LLMs locally and enables you to build local RAG workflows
for AI applications. You can also use Open Web UI to integrate with Open AI APIs.

It is acknowledged that the provision of the Open Web UI application using Cloud 
Init is not the most optimal way to provision an applications with Terraform.
This approach has been taken for simplicty, a more production ready approach would
be to use Packer to bake a VM with the software installed and then use Terraform to
deploy it. An example for Packer can be found in this repository.

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

## Authentication

To run this example you will need an AWS Account and a valid AWS access key and 
secret. An AWS Free Tier account can be used to create the CPU example shown in this
demo. You can sign up for an AWS account at the following link.

[https://aws.amazon.com/free](https://aws.amazon.com/free)

Once you have created an account you need to create an IAM user that Terraform
can use to create resources. The process for creating an IAM user is detailed in
the walk through video:

[Walk Through link]()

It is incredibly important to ensure that your credentials stay secret. Terraform
can read credentials from environment variables, rather than hard coding these credentials in an environment script, 1Password users can store them in 1Password
and then use the 1password CLI to populate the environment variables. The following script shows how you can set environment variables using the `op` CLI. This script 
can then be safely sourced from your bash profile or can be dynamically loaded using
a tool like `direnv`.

```shell
command=op

if ! [ -x "$(command -v op)" ]; then
  # op command not present, assume we are using WSL or Windows bash
	command="op.exe"
fi

export AWS_ACCESS_KEY_ID="$(${command} item get "Terraform Basics" --fields "Access Key ID")"
export AWS_SECRET_ACCESS_KEY="$(${command} item get "Terraform Basics" --fields "Access Key Secret")"
export AWS_REGION="$(${command} item get "Terraform Basics" --fields "Region")"
export TF_VAR_region="$(${command} item get "Terraform Basics" --fields "Region")"
export TF_VAR_openai_key="$(${command} item get "Terraform Basics" --fields "API Key")"
```