# Master node 
gcloud compute instances create cks-master --zone=europe-west4-a \
--machine-type=e2-medium \
--image=ubuntu-2404-noble-amd64-v20250920 \
--image-project=ubuntu-os-cloud \
--boot-disk-size=50GB \
--metadata startup-script='#!/bin/bash
  curl -fsSL https://raw.githubusercontent.com/prashanthgl/cks-course-environment/refs/heads/use-cilium/cluster-setup/install_master.sh -o /tmp/masterscript.sh
  sudo bash /tmp/masterscript.sh'

# Worker node
gcloud compute instances create cks-worker --zone=europe-west4-a \
--machine-type=e2-medium \
--image=ubuntu-2404-noble-amd64-v20250920 \
--image-project=ubuntu-os-cloud \
--boot-disk-size=50GB \
--metadata startup-script='#!/bin/bash
  curl -fsSL https://raw.githubusercontent.com/prashanthgl/cks-course-environment/refs/heads/use-cilium/cluster-setup/install_worker.sh -o /tmp/workerscript.sh
  sudo bash /tmp/workerscript.sh'

  
sudo journalctl -u google-startup-scripts.service -n 50


gcloud compute instances delete cks-master cks-worker \
    --zone =europe-west4-a \
    --quiet
