output "publisher_vm_name" {
  value = google_compute_instance.publisher_vm.name
}

output "receiver_vm_name" {
  value = google_compute_instance.receiver_vm.name
}

output "topic_name" {
  value = google_pubsub_topic.topic.name
}

output "subscription_name" {
  value = google_pubsub_subscription.subscription.name
}