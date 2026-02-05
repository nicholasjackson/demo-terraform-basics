# Terraform Basics

Source code to accompany the Terraform Basics video tutorial series. Each folder contains a complete, working example demonstrating Terraform fundamentals on different platforms.

## Video Tutorials

| Folder | Platform | Video |
|--------|----------|-------|
| [basics/](basics/) | Docker (Local) | [Terraform Basics](https://www.youtube.com/watch?v=_45W3Z8XWL4) |
| [aws/](aws/) | Amazon Web Services | [Terraform AWS Tutorial](https://www.youtube.com/watch?v=rsct-JvJmKs) |
| [gcp/](gcp/) | Google Cloud Platform | [Terraform GCP Tutorial](https://www.youtube.com/watch?v=Xni8GUcWQ_s) |
| [azure/](azure/) | Microsoft Azure | [Terraform Azure Tutorial](https://www.youtube.com/watch?v=6oJzsBl_-so) |

## Getting Started

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) (v1.0+)
- [Docker](https://www.docker.com/) (for basics tutorial)
- Cloud provider CLI and credentials (for cloud tutorials):
  - [AWS CLI](https://aws.amazon.com/cli/)
  - [gcloud CLI](https://cloud.google.com/sdk/gcloud)
  - [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/)

### Basics (Docker) - No Cloud Account Required

The `basics/` folder is the perfect starting point. It uses Docker locally, so you don't need any cloud credentials.

```bash
cd basics
terraform init
terraform plan
terraform apply
```

This creates a HashiCorp Vault container running on port 8200.

### Cloud Tutorials (AWS, GCP, Azure)

Each cloud folder deploys the same application (Open Web UI) using cloud-specific resources. All three follow identical patterns:

1. **Navigate to the folder:**
   ```bash
   cd aws  # or gcp, azure
   ```

2. **Configure credentials** (see provider-specific README)

3. **Initialize and apply:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Access the application** via the output IP address

5. **Clean up:**
   ```bash
   terraform destroy
   ```

## Repository Structure

```
.
├── basics/              # Docker-based intro (no cloud needed)
│   ├── main.tf          # Provider configuration
│   └── docker.tf        # Docker resources
│
├── aws/                 # AWS tutorial
│   ├── main.tf          # Variables and provider
│   ├── vm.tf            # Infrastructure resources
│   ├── output.tf        # Outputs
│   ├── packer/          # AMI baking configuration
│   └── scripts/         # Provisioning scripts
│
├── gcp/                 # GCP tutorial
│   ├── main.tf          # Variables and provider
│   ├── vm.tf            # Infrastructure resources
│   ├── outputs.tf       # Outputs
│   └── scripts/         # Provisioning scripts
│
└── azure/               # Azure tutorial
    ├── main.tf          # Variables and provider
    ├── vm.tf            # Infrastructure resources
    ├── output.tf        # Outputs
    └── scripts/         # Cloud-init and provisioning
```

## Terraform Concepts Demonstrated

This repository teaches the following Terraform fundamentals:

- **Providers** - Configuring cloud provider plugins
- **Resources** - Creating infrastructure (VMs, networks, security groups)
- **Data Sources** - Querying existing resources (AMIs, images)
- **Variables** - Input parameters with types and defaults
- **Outputs** - Exposing values (IP addresses, passwords)
- **Functions** - `cidrsubnet()`, `templatefile()`, `base64encode()`
- **Conditionals** - Toggling GPU/CPU instances
- **State Management** - How Terraform tracks infrastructure
- **Provisioning** - Cloud-init and startup scripts

## Common Variables

All cloud tutorials support these variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `gpu_enabled` | `false` | Use GPU-enabled instance |
| `open_webui_user` | `admin@demo.gs` | Web UI admin username |
| `openai_key` | `""` | Optional OpenAI API key |
| `ssh_pub_key` | `""` | Path to SSH public key |

## Secure Credential Management with 1Password

This repository includes a `.envrc` file for [direnv](https://direnv.net/) that integrates with [1Password CLI](https://developer.1password.com/docs/cli/) to securely manage cloud credentials.

### How It Works

Instead of storing secrets in plain text files, credentials are fetched from 1Password at runtime:

```bash
# Secrets are retrieved on-demand from 1Password
export AWS_ACCESS_KEY_ID="$(op item get "Terraform Basics" --fields "Access Key ID")"
export AWS_SECRET_ACCESS_KEY="$(op item get "Terraform Basics" --fields "Access Key Secret")"
```

### Setup

1. Install [direnv](https://direnv.net/) and [1Password CLI](https://developer.1password.com/docs/cli/)
2. Create a 1Password item named **"Terraform Basics"** with your cloud credentials
3. Run `direnv allow` in the repository directory
4. Credentials are automatically loaded when you `cd` into the folder

### Supported Credentials

| Provider | 1Password Fields Required |
|----------|--------------------------|
| AWS | "Access Key ID", "Access Key Secret", "Region" |
| GCP | "GOOGLE_CREDENTIALS", "project_id" |
| Azure | "ARM_CLIENT_ID", "ARM_SUBSCRIPTION_ID", "ARM_TENANT_ID", "ARM_CLIENT_SECRET" |
| SSH | "public key" (from "RSA SSH Key" item) |
| OpenAI | "API Key" (optional) |

### Why This Approach?

- **No secrets in files** - Credentials never touch disk in plain text
- **Safe to commit** - The `.envrc` contains no actual secrets
- **Authentication required** - 1Password requires biometric/password before releasing secrets
- **Easy rotation** - Update credentials in 1Password once, all machines get the new values

## Resources Created

Each cloud tutorial creates:

- Virtual network with subnets
- Security groups (SSH + HTTP access)
- Virtual machine (CPU or GPU)
- Public IP address
- Random password for application

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
