#/bin/sh

# import any necessary scripts
nohup aws s3 cp s3://$S3_PATH/update_tokens.sh /update_tokens.sh &
aws s3 cp s3://$S3_PATH/add_zone_label.sh ./add_zone_label.sh

# echo "set timezone to America/Chicago"
unlink /etc/localtime
ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime

# echo "run scripts"
# get the zone that the instances are running in and add to docker node's label
# this allows you to deploy containers equally in multiple zones using
# the deploy>preferences -spread:  node.labels.zone
sudo bash ./add_zone_label.sh

# cloudstor plugin allows persistent volumes on AWS and Azure
# see swarm_initial_master.sh for limitations and alternatives
# docker plugin install --alias cloudstor:aws --grant-all-permissions docker4x/cloudstor:18.03.0-ce-aws1 CLOUD_PLATFORM=AWS AWS_REGION=$AWS_DEFAULT_REGION EFS_SUPPORTED=0 DEBUG=1
