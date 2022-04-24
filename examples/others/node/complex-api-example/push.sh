#!/bin/bash

aws configure set aws_access_key_id ">> ACCESS KEY HERE <<"
aws configure set aws_secret_access_key ">> SECRET KEY HERE <<"
aws configure set region "us-west-1"

docker tag fredlackey/complexapi:0.0.0 123456789012.dkr.ecr.us-west-1.amazonaws.com/complexapi:0.0.0
docker tag fredlackey/complexapi:0.0.0 123456789012.dkr.ecr.us-west-1.amazonaws.com/complexapi:latest
aws ecr get-login-password | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-west-1.amazonaws.com
docker push 123456789012.dkr.ecr.us-west-1.amazonaws.com/complexapi:0.0.0
docker push 123456789012.dkr.ecr.us-west-1.amazonaws.com/complexapi:latest

# $ ./push.sh 
# Login Succeeded
# The push refers to repository [123456789012.dkr.ecr.us-west-1.amazonaws.com/complexapi]
# 5dbcb249607a: Pushed
# 5f70bf18a086: Pushed
# 36eb1b463826: Pushed
# 291cc65d7cfb: Pushed
# 19e9ea20d442: Pushed
# e8ede550b75c: Pushed
# 7dc3712b33d2: Pushed
# 3ffc178e6d86: Pushed
# 327e42081bbe: Pushed
# 6e632f416458: Pushed
# e019be289189: Pushed
# c9a63110150b: Pushed 
# 0.0.0: digest: sha256:7f6b8294ef098ff89668ac1c1d0d33e8c9b85f453b3751518a10674ab7aae302 size: 2836
# The push refers to repository [123456789012.dkr.ecr.us-west-1.amazonaws.com/complexapi]
# 5dbcb249607a: Layer already exists
# 5f70bf18a086: Layer already exists
# 36eb1b463826: Layer already exists
# 291cc65d7cfb: Layer already exists
# 19e9ea20d442: Layer already exists
# e8ede550b75c: Layer already exists
# 7dc3712b33d2: Layer already exists
# 3ffc178e6d86: Layer already exists
# 327e42081bbe: Layer already exists
# 6e632f416458: Layer already exists
# e019be289189: Layer already exists
# c9a63110150b: Layer already exists
# latest: digest: sha256:7f6b8294ef098ff89668ac1c1d0d33e8c9b85f453b3751518a10674ab7aae302 size: 2836
