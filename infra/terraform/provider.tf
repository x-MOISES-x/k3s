terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

provider "oci" {
  config_file_profile = "DEFAULT"
  region              = "us-ashburn-1"
}
