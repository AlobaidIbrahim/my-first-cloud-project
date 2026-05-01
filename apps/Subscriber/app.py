from flask import Flask, render_template
from google.cloud import pubsub_v1
import os

app = Flask(__name__)

PROJECT_ID = os.environ.get("GCP_PROJECT_ID", "project-ec7a15ac-1f75-4a47-a9b")
SUBSCRIPTION_ID = "simple-subscription"

subscriber = pubsub_v1.SubscriberClient()
subscription_path = subscriber.subscription_path(PROJECT_ID, SUBSCRIPTION_ID)

messages = []


def callback(message):
    text = message.data.decode("utf-8")
    messages.append(text)
    message.ack()


subscriber.subscribe(subscription_path, callback=callback)


@app.route("/")
def home():
    return render_template("index.html", messages=messages)

# the below line is for running the Flask app, it will start the web server and listen for incoming requests on all available network interfaces (
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
