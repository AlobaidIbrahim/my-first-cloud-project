terraform {
  backend "gcs" {
    bucket = "my-first-cloud-project-tfstate-12345"
    prefix = "terraform/state"
  }
}