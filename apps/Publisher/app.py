from flask import Flask, render_template, request
from google.cloud import pubsub_v1
import os

app = Flask(__name__)

PROJECT_ID = os.environ.get("GCP_PROJECT_ID", "project-ec7a15ac-1f75-4a47-a9b")
TOPIC_ID = "simple-topic"

publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(PROJECT_ID, TOPIC_ID)


@app.route("/", methods=["GET", "POST"])
def home():
    status = ""

    if request.method == "POST":
        message = request.form.get("message")

        if message:
            publisher.publish(topic_path, message.encode("utf-8"))
            status = f"Published: {message}"
# the below line is for rendering the template with the status message, it will show the status of the published message on the webpage
# index.html will be the template file that will be rendered, it should be located in the templates folder of the app directory because Flask looks for templates in the templates folder by default
    return render_template("index.html", status=status)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
