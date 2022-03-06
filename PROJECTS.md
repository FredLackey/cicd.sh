# About the Projects File

The `projects.json` file is fairly self-explanatory, so I won't go into a ton of detail about it.  Let's take a quick look at the structure and some recommended patterns.

## Structure  

Formatting of the `projects.json` file is JSON and, more specifically, a single JSON object.  Each property / key in the top-level object represents the cosmetic name of a project you are monitoring.  Past that, the breakdown is as follows:

```
Project Name / Object (required)
  Repos Object (required)
    Source Repo URL Property (required)
    Data Repo URL Property (required)
    Deploy Repo URL Property (required)
  Folders Object (required)
    Source Folder Path Property (required)
    Data Folder Path Property (required)
    Deploy Folder Path Property (required)
  Environments Object (required)
    Environment Folder Object (should have at least one)
      Branches Object (required)
        Source Branch Name Property (required)
        Data Branch Name Property (required)
        Deploy Branch Name Property (required)
      Archives Object (optional)
        Success Archive Object (optional)
          Folder Path Property (required)
          RSync Excludes Property (optional)
        Failure Archive Object (optional)
          Folder Path Property (required)
          RSync Excludes Property (optional)
```

## Object & Property Descriptions  

### Repos Object (`repos`)  

Indicates which git repos to pull from.  Three properties are required:

#### Source (`source`)

Git repo containing your application's logic.

#### Data (`data`)

Git repo containing environment-specific data.  The contents of this repo is merged with your application's source code during the build process.

#### Deploy (`deploy`)

Git repo containing at least one `deploy.sh` file for each environment.  The contents of this repo is pulled into the build folder during the build process.  You may also include files intended to overwrite files existing in the build folder in the final build stage.

### Folders Object (`folders`)  

Just like the `repos` object, above, the `folders` object tells the `cicd.sh` script where to store files for monitoring. Three properties are required:

#### Source (`source`)

Local folder path where your application's source code will be stored.

> **Important**  
> Make sure you select a storage area with plenty of space since a copy of your git repo will be created for ever branch being monitored (i.e. `feature/`, `release/`, `main`, etc.).

#### Data (`data`)

Local folder path where environment-specific data is to be stored for the build process.

> **Important**  
> Select a secure location for this storage.  Sensitive environment-specific data is commonly stored in the `-data` repo.  Lock down this folder to prevent the data from being exposed or leaked.

#### Deploy (`deploy`)

Local folder path where your environment-specific build scripts are stored for the build process.

> **Important**  
> Select a secure location for this storage.  Secrets and access keys are commonly needed to push your code into the target environment and, therefore, are often referenced in deploy scripts.  Lock down this folder to prevent this information from being exposed or leaked.

> **Note**  
> I'm considering adding a pre-build step to allow for the tokenizing of the items stored within the `-deploy` and/or `-data` repos.  This should help protect the sensitive info once implemented. 

### Environments Object (`environments`)  

Each property in the `environments` object represents the name of some environment you wish to target for deployment.  You may have as many as you wish.  It must be stressed that each environment name must also have a matching folder in your `-deploy` and `-data` repos.

#### Branches Object (`branches`)  

The monitoring stage of the `cicd.sh` script depends on items existing in the `branches` object.  The build and deploy steps are allowed to proceed whenever changes are detected in a specific branch.  Three properties are required:

##### Source (`source`)

Name or prefix of the branch to monitor in your application's source repo.  Since this is being defined _under_ the environment object, we are essentially tying a specific branch or branch prefix to an environment.  **The _source_ branch is the only branch that may contain a pattern or prefix!**  

> GitFlow Workflow ([more info](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow))  
> One of the most common workflows used to determine the branch-environment pattern is that described with [GitFlow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow).  

The examples in this repo follow a simplified approach similar to [GitFlow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow):  

| Branch | Environment |
|--|--|
| `feature/` | Development |
| `release/` | Staging |
| `main`  | Production |

##### Data (`data`)

The concrete name of the branch containing your environment-specific data (usually `main` or `mater`).  Patterns are not allowed.

##### Deploy (`deploy`)

The concrete name of the branch containing your environment-specific `deploy.sh` script (usually `main` or `mater`).  Patterns are not allowed.

#### Archives Object (`archives`)  

An optional object used to instruct the `cicd.sh` script to create an archive of the build depending on the result from the `deploy.sh` routine.  If the `archives` object is supplied you may include one or both of the `success` and `failure` objects.

#### Success Archive Object (`success`) & Failure Archive Object (`failure`)  

Optional objects containing the parameters to use after a successful (`success`) or failed (`failure`) build.

##### Folder Path Property (`path`)  

Local path to store the build contents.  All files from the build will be stored here for you review.  **This may include sensitive data!**

##### RSync Excludes Property (`excludes`)  

Optional Comma-separated list of file and folder names to exclude during the archive operation.  Some commonly excluded folders and files are:

| Pattern |  Description  |
|--|--|
| `.git` | The [usually] hidden folder used by Git.  Can be massive! |
| `node_modules` | Binaries used by NodeJS apps.  Wastes space. |
| `.env` | Usually excluded in production build archives to prevent sensitive data from leaking. |
| `.vscode` | Excluded from prod builds as it wastes space.  Helpful in non-prod builds if the app needs to be debugged.  | 


