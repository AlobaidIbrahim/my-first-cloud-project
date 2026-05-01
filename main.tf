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

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

resource "google_compute_instance" "publisher_vm" {
  name         = "publisher-vm"
  machine_type = "e2-micro"
  zone         = var.zone
  tags         = ["web-server"]

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

    apt-get update
    apt-get install -y python3 python3-pip python3-venv git

    mkdir -p /opt/publisher-app
    cd /opt/publisher-app

    python3 -m venv venv

    cat > requirements.txt <<REQ
    flask
    google-cloud-pubsub
    gunicorn
    REQ

    ./venv/bin/pip install -r requirements.txt

    cat > app.py <<APP
    from flask import Flask

    app = Flask(__name__)

    @app.route("/")
    def home():
        return "Publisher app placeholder. Deploy real app from GitHub."

    if __name__ == "__main__":
        app.run(host="0.0.0.0", port=80)
    APP

    cat > /etc/systemd/system/publisher-app.service <<SERVICE
    [Unit]
    Description=Publisher Flask App
    After=network.target

    [Service]
    WorkingDirectory=/opt/publisher-app
    ExecStart=/opt/publisher-app/venv/bin/gunicorn --bind 0.0.0.0:80 app:app
    Restart=always
    User=root

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable publisher-app
    systemctl restart publisher-app
  EOF

  depends_on = [
    google_pubsub_topic.topic,
    google_project_iam_member.pubsub_publisher,
    google_compute_firewall.allow_http
  ]
}

resource "google_compute_instance" "receiver_vm" {
  name         = "receiver-vm"
  machine_type = "e2-micro"
  zone         = var.zone
  tags         = ["web-server"]

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

    apt-get update
    apt-get install -y python3 python3-pip python3-venv git

    mkdir -p /opt/receiver-app
    cd /opt/receiver-app

    python3 -m venv venv

    cat > requirements.txt <<REQ
    flask
    google-cloud-pubsub
    gunicorn
    REQ

    ./venv/bin/pip install -r requirements.txt

    cat > app.py <<APP
    from flask import Flask

    app = Flask(__name__)

    @app.route("/")
    def home():
        return "Receiver app placeholder. Deploy real app from GitHub."

    if __name__ == "__main__":
        app.run(host="0.0.0.0", port=80)
    APP

    cat > /etc/systemd/system/receiver-app.service <<SERVICE
    [Unit]
    Description=Receiver Flask App
    After=network.target

    [Service]
    WorkingDirectory=/opt/receiver-app
    ExecStart=/opt/receiver-app/venv/bin/gunicorn --bind 0.0.0.0:80 app:app
    Restart=always
    User=root

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable receiver-app
    systemctl restart receiver-app
  EOF

  depends_on = [
    google_pubsub_subscription.subscription,
    google_project_iam_member.pubsub_subscriber,
    google_compute_firewall.allow_http
  ]
}