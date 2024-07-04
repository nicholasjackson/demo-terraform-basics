// This is the same as doing:
// docker pull hashicorp/vault:1.12.6
resource "docker_image" "vault" {
  name = "hashicorp/vault:1.12.6"
}

// This is the same as doing:
// docker run -p 8200:8200 --name "terraform-basics-vault" hashicorp/vault:1.12.6
resource "docker_container" "vault" {
  name  = "terraform-basics-vault"
  image = docker_image.vault.image_id

  ports {
    internal = 8200
    external = 8200
  }
}