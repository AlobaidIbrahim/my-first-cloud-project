provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

data "google_compute_default_service_account" "default" {}

resource "google_project_iam_member" "pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_project_iam_member" "pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_pubsub_topic" "topic" {
  name = "simple-topic"
}

resource "google_pubsub_subscription" "subscription" {
  name  = "simple-subscription"
  topic = google_pubsub_topic.topic.name
}

resource "google_compute_instance" "publisher_vm" {
  name         = "publisher-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }
// Configure the VM to have external internet access
  network_interface {
    network = "default"
    access_config {}
  }

  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }
// Startup script to publish messages to Pub/Sub every 30 seconds
  metadata_startup_script = <<-EOF
    #!/bin/bash
    echo "Publisher VM started"

    while true; do
      gcloud pubsub topics publish simple-topic \
        --message="Hello from publisher-vm at $(date)"

      sleep 30
    done
  EOF

  depends_on = [
    google_pubsub_topic.topic,
    google_project_iam_member.pubsub_publisher
  ]
}

resource "google_compute_instance" "receiver_vm" {
  name         = "receiver-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    echo "Receiver VM started"

    while true; do
      gcloud pubsub subscriptions pull simple-subscription \
        --auto-ack \
        --limit=1

      sleep 10
    done
  EOF

  depends_on = [
    google_pubsub_subscription.subscription,
    google_project_iam_member.pubsub_subscriber
  ]
}