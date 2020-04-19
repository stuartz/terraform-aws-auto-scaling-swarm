# Auto-scaling Swarm on AWS
## Summary
This project installs
 - a master EC2 on-demand instance
 - auto-scaling groups of spot-instances (one for masters and one for workers) to run a docker swarm on
 - a loadbalancer and target groups specified
 - a peering connection if specified.

There is ability to add persistent volumes to the swarm depending on instances chosen.  Documentation links
are included to other alternatives if needed on instances using NVMe storage.

If you use the example_scripts as mentioned below, it will also
install swarmpit and portainer on the swarm for monitoring.  Those scripts can be used
as a model to add more stacks automatically to your swarm on initiation.

## This is Used With the Following Folder Structure.

>_/

>__/aws- _region_

>____/dev                (git clone https://github.com/VernonCo/AWS_auto-scaling_swarm.git dev)

>____/prod

>__/modules

>____/terraform-aws-vpc  (git clone https://github.com/terraform-aws-modules/terraform-aws-vpc.git)
>____/terrafrom-aws-vpc-peering (git clone https://github.com/grem11n/terraform-aws-vpc-peering.git)

## Uses Terraform 0.12
Variables are not quoted, and code is not backwards compatible with 0.11

## Useage
### Configure Variables for Your Use.
Create a region/dev/terraform.tfvars which will automatically be imported by terraform to override desired variables in variables.tf  Number of nodes, instance sizes, etc. are all configurable.
### Apply the Resources
Do `terraform init` in region/dev/ and then run `terraform apply`.  It will show you what resources will be created but will not create them unless you specifically type in 'yes' and hit enter.  If you hit enter with anything else, the apply will be canceled.

## What it Can Do
aws-auto-scaling-swarm can create the resources needed to run a swarm on AWS including a application load balancer (alb) with target groups you specify that would target ports on the swarm for web resources. Some of the resources are:
  - VPC
  - Security groups
  - route tables
  - private and public subnets in each zone
  - S3 bucket for scripts
  - alb
  - target groups
  - initial master using on-demand instance
  - auto scaling groups (masters, workers)
  - auto scaling configs (masters, workers) using spot instances
  - auto scaling policies based on cpu ( you can add based on free memory)
  - peering connection (optional)
### Initial Swarm Master
An initial on-demand (if reserved is desired, change in main.tf) swarm master is created to begin the process. It sets up swarm tokens and runs stacks.  It also has an public IP to access it from the allowed IP.
#### Cron Jobs, Scripts & Stacks
This swarm master can download scripts & stacks and a crontab.txt to run cronjobs from a S3 bucket (see the user_data in main.tf for the initial master and swarm_initial_master.sh) There is a sleep time while the intial swarm master waits for the other nodes to come up before creating the stacks.

s3_bucket.tf will create a bucket and upload scripts from root folder and ./example_scripts  Example scripts install swarmpit and portainer, two Swarm UI management apps.

If S3 scripts are not used, you can still ssh into the initial master to copy/create scripts and stacks to run.
#### AWS Secret Manager for Swarm Token
The initial swarm master will create swarm tokens and save them to the AWS secrets manager for the other nodes to retrieve.
### Swarm Master Nodes
You can set the number of swarm master nodes running on spot instances (if on-demand or reserved is desired, change in main.tf). (recommend even numbers to go with the initial master for an odd number of masters. ie. 2 masters + initial master = 3 masters).  They are started on an auto-scaling group and retrieve their swarm token from the AWS secrets manager.  In case of an auto-scaling later, you may need to <a href="https://docs.docker.com/engine/swarm/admin_guide/#force-the-swarm-to-rebalance" target="_blank">`manually manage container dispersion`</a>.


When they start up with the terrafrom apply, any scripts to load stacks that are ran on the initial master should apply to these masters.
### Swarm Worker Nodes
You can set the desired number of swarm worker nodes running on spot instances (if on-demand or reserved is desired, change in main.tf). They are started on an auto-scaling group and retrieve their swarm token from the AWS secrets manager.  In case of an auto-scaling later, you may need to <a href="https://docs.docker.com/engine/swarm/admin_guide/#force-the-swarm-to-rebalance" target="_blank">`manually manage container dispersion`</a>.

When they start up with the terrafrom apply, any scripts to load stacks that are ran on the initial master should apply to these workers.
### Multiple Target Groups, Multiple Domains, Multiple SSL Certificates
target_groups and ssl_arns variables allow you to set multiple targets and domains. See the variables in variables.tf and alb.tf
### Peering Connection to Default VPC
Can enable a peering connection to the default VPC to be able to connect to resources on the default VPC.  Does not take much to enable a cross region peering connection if needed (see commented out section of peering_vpc.tf).

## State Storage (recommended)
Recomend setting up a tf state on aws S3 and dynamodb (Otherwise, remove tf-state.tf to store locally).  External storage on AWS allows multiple developers to use the same code and lock others out while running apply to prevent mangled configurations.
#### Create S3 Bucket and Dynamodb Table for TF State
Add a region/dev/state/terraform.tfvars to override variables in region/dev/state/main.tf.  Then in region/dev/state run:

  `terraform init`

  `terraform apply`

It will create an S3 bucket and a global dynamodb lock table with replications in 2 regions of your choice.  You can easily change it to have only one replication or as many as you like.
#### Create tf-state.tf in Environment Folder for Environment State Storage
Dev has file already to be edited. Otherwise, you can copy the example in dev/state/backend-example to edit.

  `cp backend-example/tf-state.tf path_to_environment_folder/`

cd to region/dev and rerun `terraform init` to use the new bucket and lock table. You should see

  'Successfully configured the backend "s3"! Terraform will automatically use this backend unless the backend configuration changes.'
