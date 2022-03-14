#!/bin/bash

deploy-sh() {

  # Only performs build if the tag is new to the ECR repository.  If the tag is unique, this
  # script an ECR repo is created (if needed) and the NodeJS app is built, tagged, and pushed to ECR.
  #
  # Note:
  # Script uses "--image-tag-mutability" when creating the ECR repo to allow updating of "latest" tag.

  AWS_ACCOUNT_ID=">> REPLACE WITH YOUR ACCOUNT ID <<"
  AWS_ACCESS_KEY=">> REPLACE WITH YOUR ACCESS KEY <<"
  AWS_SECRET_KEY=">> REPLACE WITH YOUR SECRET KEY <<"

  ECS_REGION="us-east-1"
  ECR_REPO_NAME="myproject-api"

  ECR_REPO_ARM="arn:aws:ecr:$ECS_REGION:$AWS_ACCOUNT_ID:repository/$ECR_REPO_NAME"
  ECR_REPO_URI="$AWS_ACCOUNT_ID.dkr.ecr.$ECS_REGION.amazonaws.com"

  SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
  SCRIPT_PATH="$(dirname $SCRIPT_PATH)"
  ROOT_PATH="$SCRIPT_PATH/deploy"

  PKG_VERSION=$(jq -r .version $ROOT_PATH/package.json)

  DOCKERFILE_PREFIX="LABEL version="
  DOCKERFILE_VERSION=$(cat $ROOT_PATH/Dockerfile | grep "$DOCKERFILE_PREFIX")
  DOCKERFILE_VERSION=${DOCKERFILE_VERSION#"$DOCKERFILE_PREFIX"}
  DOCKERFILE_VERSION=${DOCKERFILE_VERSION%\"}
  DOCKERFILE_VERSION=${DOCKERFILE_VERSION#\"}

  if [ $PKG_VERSION != $DOCKERFILE_VERSION ]; then
    echo "          dockerfile / package version mismatch"
    return 1
  fi

  eval "aws configure set aws_access_key_id \"$AWS_ACCESS_KEY\""
  eval "aws configure set aws_secret_access_key \"$AWS_SECRET_KEY\""
  eval "aws configure set region \"$ECS_REGION\""

  ECR_REPO_DATA=$(aws ecr describe-repositories --repository-names $ECR_REPO_NAME 2>&1)
  if [ $? -ne 0 ]; then
    if echo ${ECR_REPO_DATA} | grep -q RepositoryNotFoundException; then
      echo "          creating repo"
      ECR_REPO_DATA=$(aws ecr create-repository --repository-name $ECR_REPO_NAME --image-tag-mutability MUTABLE 2>&1)
      if [ $? -ne 0 ]; then
        echo "          repo create failed"
        return 2
      else
        echo "          repo created"
      fi
    else
      echo "          unknown failure creating repo"
      return 3
    fi
  else
    echo "          repo exists"
  fi

  TAG_DATA=$(aws ecr describe-images --repository-name $ECR_REPO_NAME --query 'imageDetails[*].imageTags[ * ]' --output json | jq flatten | tr -d \")
  if [[ "${TAG_DATA[*]}" =~ "${DOCKERFILE_VERSION}" ]]; then
    echo "          tag already exists"
    return 4
  fi

  eval "cd $ROOT_PATH && docker build -t $ECR_REPO_NAME:$DOCKERFILE_VERSION ."
  if [ $? -ne 0 ]; then
    return 5
  fi

  eval "docker tag $ECR_REPO_NAME:$DOCKERFILE_VERSION $ECR_REPO_URI/$ECR_REPO_NAME:$DOCKERFILE_VERSION"
  if [ $? -ne 0 ]; then
    return 6
  fi

  eval "docker tag $ECR_REPO_NAME:$DOCKERFILE_VERSION $ECR_REPO_URI/$ECR_REPO_NAME:latest"
  if [ $? -ne 0 ]; then
    return 7
  fi

  eval "aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_REPO_URI"
  if [ $? -ne 0 ]; then
    return 8
  fi

  eval "docker push $ECR_REPO_URI/$ECR_REPO_NAME:$DOCKERFILE_VERSION"
  if [ $? -ne 0 ]; then
    return 9
  fi

  eval "docker push $ECR_REPO_URI/$ECR_REPO_NAME:latest"
  if [ $? -ne 0 ]; then
    return 10
  fi

  return 0
}
