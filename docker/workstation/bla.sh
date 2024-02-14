#!/bin/bash

sudo -u ec2-user -i <<'EOF'

# This only work if Sagemaker Notebook is on a VPC and has
#   "Direct Internet Access = Enable Access the internet directly through Amazon SageMaker"
#   Sagemaker instances have two Network Interfaces.  The GLG subnet will be allocated to eth2
#   Output traffic goes through eth0 which is Sagemaker's AWS network
#   This route directs internal AWS traffic to use eth2 which has access to our VPC peering etc.
#
#   Related documentation:
#   https://aws.amazon.com/premiumsupport/knowledge-center/sagemaker-connect-rds-db-different-vpc/
sudo ip route add 172.16.0.0/12 via "$(route -n | grep 'UG.*eth2' | awk '{print $2}')" dev eth2

TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id -H "X-aws-ec2-metadata-token: $TOKEN")
INSTANCE_TYPE=$(curl http://169.254.169.254/latest/meta-data/instance-type -H "X-aws-ec2-metadata-token: $TOKEN")
NOTEBOOK_NAME=$(jq '.ResourceName' /opt/ml/metadata/resource-metadata.json --raw-output)
cat <<AOF | sudo tee /tmp/telegraf.conf >/dev/null
[global_tags]
  environment = "production"
  account_name = "insights"
  partition = "aws"
  instance_id="$INSTANCE_ID"
  notebook_name = "$NOTEBOOK_NAME"

[agent]
  interval = "30s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "30s"
  flush_jitter = "0s"
  precision = ""
  # debug = false
  # quiet = false
  # logtarget = "file"
  # logfile = ""
  # logfile_rotation_interval = "0d"
  # logfile_rotation_max_size = "0MB"
  # logfile_rotation_max_archives = 5
  # log_with_timezone = ""
  hostname = ""
  omit_hostname = false

[[outputs.sumologic]]
  url = "https://endpoint3.collection.us2.sumologic.com/receiver/v1/http/ZaVnC4dhaV2lXuFzgmeKHQnoKPttah8kR8FWrxXAGkcWqHH7KLeO1Q6MoaIclWIphzA8FxB8EetzwFciasbxp-iH0UFYkFy6BEcg__Fwi4OpMNv1N6xsMQ=="
  data_format = "carbon2"
  # timeout = "5s"
  # max_request_body_size = 1000000
  # source_name = ""
  # source_host = ""
  # source_category = ""
  # dimensions = ""

[[processors.aws_ec2]]
  ## https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-identity-documents.html
  imds_tags = ["accountId", "region"]

[[inputs.cpu]]
  percpu = true
  fieldpass = ["usage_idle", "usage_user", "usage_system"]

[[inputs.disk]]
  mount_points = ["/"]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]
  fieldpass = ["total", "used", "free"]

[[inputs.mem]]
  fieldpass = ["total", "used", "free"]
AOF

if [[ "${INSTANCE_TYPE}" =~ ^[p|g] ]]
then
  echo this is a gpu machine

cat <<AOF | sudo tee -a /tmp/telegraf.conf >/dev/null
[[inputs.nvidia_smi]]
  # bin_path = "/usr/bin/nvidia-smi"
  timeout = "5s"
  fieldpass = ["memory_free", "memory_used", "memory_total", "temperature_gpu", "utilization_gpu", "utilization_memory"]
AOF
fi

cat <<AOF | sudo tee /etc/yum.repos.d/influxdata.repo
[influxdata]
name = InfluxData Repository - Stable
baseurl = https://repos.influxdata.com/stable/\$basearch/main
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdata-archive_compat.key
AOF

sudo yum install telegraf -y
if which telegraf &> /dev/null; then
  telegraf --config /tmp/telegraf.conf --test
  sudo cp /tmp/telegraf.conf /etc/telegraf/telegraf.conf
  sudo service telegraf start
else
  >&2 echo ":: telegraf was not successfully installed"
fi

EOF
