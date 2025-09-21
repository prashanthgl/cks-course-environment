# Master node 
gcloud compute instances create cks-master --zone=europe-west4-a \
--machine-type=e2-medium \
--image=ubuntu-2404-noble-amd64-v20250920 \
--image-project=ubuntu-os-cloud \
--boot-disk-size=50GB \
--metadata startup-script='#!/bin/bash
  curl -s https://raw.githubusercontent.com/prashanthgl/cks-course-environment/refs/heads/use-cilium/cluster-setup/latest/install_master.sh -o /tmp/master_script.sh
  sudo bash /tmp/master_script.sh'

# Worker node
gcloud compute instances create cks-worker --zone=europe-west4-a \
--machine-type=e2-medium \
--image=ubuntu-2404-noble-amd64-v20250920 \
--image-project=ubuntu-os-cloud \
--boot-disk-size=50GB \
--metadata startup-script='#!/bin/bash
  curl -fsSL https://raw.githubusercontent.com/prashanthgl/cks-course-environment/refs/heads/use-cilium/cluster-setup/latest/install_worker.sh -o /tmp/worker_script.sh
  sudo bash /tmp/worker_script.sh'

  
