terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.63.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.24.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "2.8.0"
    }

    time = {
      source  = "hashicorp/time"
      version = "0.14.2"
    }
  }
}
