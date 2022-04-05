#!/bin/bash

docker tag fredlackey/complexapi:0.0.0 123456789012.dkr.ecr.us-gov-west-1.amazonaws.com/complexapi:0.0.0

docker tag fredlackey/complexapi:0.0.0 123456789012.dkr.ecr.us-gov-west-1.amazonaws.com/complexapi:latest

aws ecr get-login-password --profile gov-staging  | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-gov-west-1.amazonaws.com

docker push 123456789012.dkr.ecr.us-gov-west-1.amazonaws.com/complexapi:0.0.0

docker push 123456789012.dkr.ecr.us-gov-west-1.amazonaws.com/complexapi:latest
