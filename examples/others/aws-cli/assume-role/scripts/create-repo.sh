#!/bin/bash

aws ecr get-login-password --profile gov-staging | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-gov-west-1.amazonaws.com

aws ecr create-repository --profile gov-staging  --repository-name "complexapi" --image-tag-mutability MUTABLE 
