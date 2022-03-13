# Example Deploy Repo (Empty Version)

This folder contains an example layout of what your `-deploy` repo will look like.  Note the names of the folders.  These folder names are the names of your environments and must be consistent throughout your `project.json` file, your `-deploy` repo, and your `-data` repo.  The contents of these folders what is merged during the build process.  Anything you place in the root (`/`) of this repo, such as this `README.md` file, is ignored.

## The one required file: `deploy.sh`

Each one of your environment-specific folders **must** contain a `deploy.sh` file.  That file **must** contain a function called "`deploy-sh()`" without any parameters.  You may create _other_ functions inside this file, if your `deploy-sh()` function will make use of them, however the `deploy-sh()` function must always exist.

### Return Codes

Your `deploy-sh()` function **must** return a success code.  If you're unsure of what this means, just remember that returning `0` tells the next process that everything in your function worked as expected.  Returning any other number (I tend to use `1`) indicates a failure or unexpected result.

```bash
#!/bin/bash

# "Development Deployment File"

example-function() {
  echo ">>> EXAMPLE FUNCTION CALLED FOR DEVELOPMENT <<<"
}

deploy-sh() {
  # 0=success / 1=failure
  return 0    
}
```