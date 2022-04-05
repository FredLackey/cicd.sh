Targetting a sub-account within the AWS CLI is not obvious.  This area contains example config files as well as two example scripts.  Both are used in conjunction.

The config files are example replacements for the files in your `~/.aws` area...

| File | Target |
|--|--|
| [`./dot-aws/config.txt`](./dot-aws/config.txt) | `~/.aws/config` |
| [`./dot-aws/credentials.txt`](./dot-aws/credentials.txt) | `~/.aws/credentials` |

This shows the overall structure of the files.  The key in assuming assume a role using the AWS CLI with ECR is that you must use the `--profile` property within your scripts and structure the `~/.aws/config` with two properties together: `role_arn` and `source_profile`

Once in place, your commands will reference the profile containing the role you wish to assume (the target account) and, where needed, you use that account ID. In the example of the `get-login-password` command, the AWC CLI is passed the `--profile` property using the name of the sub-account. Docker will receive the resulting password from the AWS CLI and directly reference the sub-account by number.

For example, here are the commands to create the AWS ECR repository in the sub-account (note both the sub-account ID is used as well as the name of that account's profile):

```
aws ecr get-login-password --profile gov-staging | docker login \
  --username AWS \
  --password-stdin 123456789012.dkr.ecr.us-gov-west-1.amazonaws.com

aws ecr create-repository \
  --profile gov-staging \
  --repository-name "complexapi" \
  --image-tag-mutability MUTABLE
``` 
... and the commands needed to push an image into the sub-account's registry with both the latest tag and a proper version number:
```
docker tag fredlackey/complexapi:0.0.0 \
  123456789012.dkr.ecr.us-gov-west-1.amazonaws.com/complexapi:0.0.0

docker tag fredlackey/complexapi:0.0.0 \
  123456789012.dkr.ecr.us-gov-west-1.amazonaws.com/complexapi:latest

aws ecr get-login-password \
  --profile gov-staging | docker login \
  --username AWS \
  --password-stdin 123456789012.dkr.ecr.us-gov-west-1.amazonaws.com

docker push 123456789012.dkr.ecr.us-gov-west-1.amazonaws.com/complexapi:0.0.0

docker push 123456789012.dkr.ecr.us-gov-west-1.amazonaws.com/complexapi:latest