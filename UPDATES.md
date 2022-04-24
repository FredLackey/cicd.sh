# Project Updates

## April 23, 2022  

* Added [`aws-ecs-boundaries`](./examples/others/terraform/aws-ecs-boundaries.tf) example showing how to spin up a new AWS environment using security boundaries and load balancers.

* Added [`complex-api-example`](./examples/others/node/complex-api-example/) Node API example showing how to deal with a custom base path (needed for the `aws-ecs-boundaries` example).

## April 5, 2022  

* Added [`aws-cli/assume-role`](./examples/others/aws-cli/assume-role/) folder with examples showing how to assume the role of a child account, create an ECR repository in the child account, and to push a dockerized API to that child account using the role ARN.

## March 24, 2022  

* Added `aws-ec2-ping-api.tf` file as Terraform example for EC2 Amazon Linux.  Similar to `aws-ec2-ping-nginx.tf` but shows the addition of a execution role which is needed for EC2/ECR services.

## March 23, 2022  

* Added `aws-ec2-ping-nginx.tf` file as Terraform example for EC2 Amazon Linux.  Can be used to test basic ECS functionality in the target account.

## March 18, 2022  

* Added `aws-ec2-amazonlinux.tf` file as Terraform example for EC2 Amazon Linux.

* Added `aws-ec2-ubuntu.tf` file as Terraform example for EC2 Ubuntu.

## March 12, 2022  

* Refactored the main `cicd.sh` script to make use of functions in an effort to aide newcomers in understanding functionality and process.

* Expanded logic for `-deploy` and `-data` repos to allow for prefixes in branch names.

* Updated [`PROJECTS.md`](./PROJECTS.md) file to show path names more similar to real-world scenarios.

* Added [`UPDATES.md`](./UPDATES.md) file to help convey changes more easily to project visitors.

## March 13, 2022  

* Created an area for example `deploy.sh` files along with the first example for pushing a Dockerized Node app to AWS ECR.  