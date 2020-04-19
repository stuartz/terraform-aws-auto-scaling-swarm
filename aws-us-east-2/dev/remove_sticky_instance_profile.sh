#!/bin/sh
# if manually deleting resources of a broken terraform state
# this is the only way to remove this resouce
aws iam delete-instance-profile --instance-profile-name "dev-swarm-profile"
