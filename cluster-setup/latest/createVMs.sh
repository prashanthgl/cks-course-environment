gcloud compute instances create INSTANCE_NAME \
  --metadata startup-script='#!/bin/bash
  curl -fsSL https://raw.githubusercontent.com/your/repo/master/script.sh -o /tmp/script.sh
  sudo bash /tmp/script.sh'
