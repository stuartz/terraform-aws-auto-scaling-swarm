# # Create a Manged Instance on spotinst.com
# resource "spotinst_managed_instance_aws" "default-managed-instance" {
#   name        = "default-managed-instance"
#   description = "created by Terraform"
#   region      = "us-west-2"
#   life_cycle      = "on_demand"
#   orientation    = "balanced"
#   draining_timeout = "120"
#   fallback_to_ondemand  = false
#   utilize_reserved_instances = "true"
#   optimization_windows = ["Mon:03:00-Wed:02:20"]
#   revert_to_spot {
#     perform_at = "always"
#   }
#   persist_private_ip = "false"
#   persist_block_devices = "true"
#   persist_root_device = "true"
#   block_devices_mode = "reattach"
#   health_check_type = "EC2"
#   auto_healing = "true"
#   grace_period = "180"
#   unhealthy_duration = "60"
#   subnet_ids = ["subnet-123"]
#   vpc_id = "vpc-123"
#   elastic_ip = "ip"
#   private_ip = "ip"
#   instance_types = [
#     "t1.micro",
#     "t3.medium",
#     "t3.large",
#     "t2.medium",
#     "t2.large",
#     "z1d.large"]
#   preferred_type = "t1.micro"
#   ebs_optimized = "true"
#   enable_monitoring = "true"
#   placement_tenancy = "default"
#   product     = "Linux/UNIX"
#   image_id              = "ami-1234"
#   iam_instance_profile  = "iam-profile"
#   security_group_ids = ["sg-234"]
#   key_pair = "labs-oregon"
#   tags {
#       key = "explicit1"
#       value = "value1"
#     }

#   tags {
#       key = "explicit2"
#       value = "value2"
#     }
#   user_data  = "managed instance hello world"
#   shutdown_script = "managed instance bye world"
#   cpu_credits = "standard"
# }
