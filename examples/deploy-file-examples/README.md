# Other Deploy Examples  

This folder contains (or will contain) examples of possible `deploy.sh` files for common scenarios.  Please feel free to contribute your own example file or, if you need a hand, reach out for assistance crafting one.  

> Note:  
> The name of each file is meant to be descriptive.  Remember that the main file within your `-deploy` repo _must_ be named `deploy.sh`.

## Current Examples  

**`docker-node-ecr.sh`**  
Creates an ECR repo (if needed) and builds, tags, and pushes a Dockerized NodeJS app to ECR.  Note that the ECR repo is set to `--image-tag-mutability MUTABLE` to allow tags to be overwritten.  This is neccessary to allow the `latest` tag to be updated.

**`docker-node-ecr-tags.sh`**  
Same as `docker-node-ecr.sh`, above, but adds a check to ensure the desired tag does not already exist in the ECR repo.  This accounts for the `--image-tag-mutability MUTABLE` flag that was used to allow the `latest` tag to be updated.
