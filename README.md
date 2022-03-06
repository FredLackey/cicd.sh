# cicd.sh

The goal of this project it to minimize the effort in detecting git changes and deploying your software.  Only two files exist within this project:  

**A single script file: `cicd.sh`**  
You should never need to edit the script.  All of the decision making is handled here.  

**A single config file: `projects.json`**  
The supplied file acts as a template for the data you need to add.  All of your projects and repos are defined here.  

## Goal  

Most CICD tools are costly (either from a monetary perspective or by consuming developer resources), complex, and try to accomplish far too much.  And, to use them properly, developers usually end up having to become "CICD gurus" and master opinionated logic that can never be leveraged outside of that specific CICD product.  At the end of the day, developers need to watch their codebase for changes and know that their software will be deployed without them having to intervene.  And, since developers who built the application already understand how to install and launch their software, forcing a devops person to duplicate such efforts is wasteful.  The `cicd.sh` script is intended to be a simplistic tool to track changes in all repos and branches, build the codebase using proven techniques, and then launch the deployment using a script the developer probably already wrote.

## Technical Requirements

This script is designed to run on a Linux machine or container.  It was written and tested using MacOS, Ubuntu, and WSL (running Ubuntu).  Other than that, you must ensure the following requirements are met:

**BASH**  ([//gnu.org...](https://www.gnu.org/software/bash/))  
The script uses BASH as the only language.  Without this you are dead in the water.

**git**  ([//wikipedia...](https://en.wikipedia.org/wiki/Git))  
It is up to you to ensure git is installed and properly configured for the user account which will run the `cicd.sh` script.

**rsync**  ([//samba.org...](https://rsync.samba.org/))  
During the file merge operations both `cp` and `rsync` are used.  Most distros contain rsync but you may want to double check before starting.

**jq**  ([//stedolan...](https://stedolan.github.io/jq/))  
The `jq` utility is used to parse the `projects.json` file.  Ensure it is installed.

**ssh**  ([//wikipedia...](https://en.wikipedia.org/wiki/Web-based_SSH))  
At the moment, everything I've tested uses SSH as the communication protocol with git.  You must ensure it is configured to work with your git repo before continuing.  

## 12-Factor(ish) Methodology

Read about the [12 Factor](https://12factor.net/) delivery methodology as I will only touch on it here.  However, in short, this project borrows a few principals you should understand before proceeding.  The two points you should note before continuing are:

**Source code must not contain secrets or environment-specific data.**  
Environment-specific data (ie seed files, secrets, keys, etc.) are _never_ stored in your source code.  Some data is loaded into memory at runtime, using a utility like "[dotenv](https://github.com/motdotla/dotenv)".  Other files are injected into the final build as it is deployed to the environment (seed files, etc.).  This ensures your source repo remains as clean as possible at all times without the potential of leaking sensitive information to less-secure environments.  

**Deployment scripts and tools do not belong in your source repo.**  
The steps needed to deploy an app often change based on the environment it is targeting.  Those tools and scripts commonly contain sensitive information (ie account numbers, access keys, etc.) which developers should not need to know.  Making the mistake of including this deployment logic in your source code increases the fragility and sensitivity of your codebase.  In short, deployment logic, tools, and scripts are stored outside of your application logic.

## (Your) Project Structure  

To use the `cicd.sh` project for deploying your software, you must first ensure your application is broken apart into **three** separate source code repositories.  Assuming you were crafting the `myproject` data API project, the three git repositories you would need to create are:

**Your source repo: `myproject`**  
All of your application logic is stored with whatever name you desire.  Remember to _not_ include any environment specific data or deployment scripts.  

**Your data repo: `myproject-data`**  
Anything environment-specific is stored in a repo with the same name plus a `-data` suffix.  Within that repo you will create one folder for each target environment used during the deployment stage.  And, finally, within that folder contains all of the files as they would exist once they are _overlaid_ into your source repo.  That's a key principal... overlaying files.  You'll follow the same folder structure as your application and place files where they will go once the two repos are combined.  If the file exists in the same location in both repos, the file from the `-data` repo will overwrite the file in your app's source repo.  Here's what it would look like if your project needed a custom `Dockerfile` and `.env` file during the build:

```bash
$ tree /myproject-data

    /
    / -- development
         |- .env
         |- Dockerfile
    / -- staging
         |- .env
         |- Dockerfile
    / -- production
         |- .env
         |- Dockerfile

```

**Your deployment repo: `myproject-deploy`**  
The third and final repo you will need follows the same "suffix" naming and folder structure as the `-data` repo did.  You'll create the same folder structure in this repo.  The only difference is that this one will store all of your deployment scripts in this folder.  And, finally, you **must** author and include one file with a special name, "`deploy.sh`".  You can add as many other files as you need or want but the `deploy.sh` file must exist (ie other utils scripts, secrets, keys, etc.).  This is the file which will be launched to perform your app's deployment.  Be careful, however, since the contents of _this_ folder can overwrite what the other two repos provided.  At a minimum, your `-deploy` repo will look like this:

```bash
$ tree /myproject-deploy

    /
    / -- development
         |- deploy.sh
    / -- staging
         |- deploy.sh
    / -- production
         |- deploy.sh

```

## The `project.json` File  

The `project.json` file may contain as many projects as you desire... 1, 10, 100... it's all the same.  The two top-level nodes, `repos` and `folders` are fairly straight forward and only contain a few strings.  The `environments` node, however, is where the fun happens.  Create as many environment objects as you like as long as they each have a unique name.

> Note:  
> At the time of this writing, the only data in each environment node is a single `branches` object.  It looks a bit odd now but, if we're going to expand on an area of this script, it's probably going to be here; hence the nested objects.

## Branches & Branch Names  

The source repo is expected to use common git prefixes for releases.  Branch prefixes like `feature/`, `release/`, and `hotfix/` are common. Granted, you don't _need_ to use them in your source code repo.  However, if you do, just note that the `source` repo is the only one that may currently use them.  The `-deploy` and `-data` repos, however, must be concrete (ie `master`, `main`, etc.).

> Note:  
> Please let me know if you feel the name prefix logic should be extended into `-deploy` and `-data`.  I did ask for several opinions from trusted dev gurus, along the way, and they all felt it added complexity that would probably never be used.


```json
{
  "myproject": {
    "repos": {
      "source": "ssh://gitservername/myproject",
      "data"  : "ssh://gitservername/myproject-data",
      "deploy": "ssh://gitservername/myproject-deploy"
    },
    "folders": {
      "source": "/cicd-sh/myproject",
      "data"  : "/cicd-sh/myproject-data",
      "deploy": "/cicd-sh/myproject-deploy"
    },
    "environments": {
      "development": {
        "branches": {
          "source": "feature/",
          "data"  : "master",
          "deploy": "main"
        }
      },
      "staging": {
        "branches": {
          "source": "release/",
          "data"  : "master",
          "deploy": "main"
        }
      },
      "production": {
        "branches": {
          "source": "main",
          "data"  : "master",
          "deploy": "main"
        },
        "archives": {
          "success" : {
            "path"  : "/cicd-sh/_success",
            "excludes" : ".git,.env,node_modules,.vscode"
          },
          "failure" : {
            "path"  : "/cicd-sh/_failure",
            "excludes" : ".git,.env,node_modules,.vscode"
          }
        }
      }
    }
  }
}
```

## Example Output  

Below is an example of what the script will show at runtime.  This example only has one project in it.  It simply repeats if there are more than one.  When looking at the example, there are a few things to note:

**Prefixed Branch Names Recurse**  

Using a branch name beginning with the `prefix/` pattern will cause all branches with that prefix to be separately examined and processed.  This means it is possible for one feature or release branch to step on another in your target environment.  Talk to your team and plan accordingly.  

**Script Stops at "Build Staged"**  

At the time of this writing the script ends at assembling the build folder.  It's there for you to examine, however I have not yet implemented the actual deployment step.  Take a look at the `development` / `feature/f001b` example to see what I'm talking about.

```bash
$ ./cicd.sh

myproject
  Folders:
    source : /cicd-sh/myproject
    data   : /cicd-sh/myproject-data
    deploy : /cicd-sh/myproject-deploy
  Repos:
    source : ssh://gitservername/myproject
             ... updating
    data   : ssh://gitservername/myproject-data
             ... updating
    deploy : ssh://gitservername/myproject-deploy
             ... updating
  Environments:
    development (feature/)
      processing feature/f001a
        detecting changes
        no changes ... skipping
      processing feature/f001b
        detecting changes
        removing old build path
        assembling build folder
        build staged
        executing deploy script
        success reported
        no archive path set
      processing feature/f002a
        detecting changes
        no changes ... skipping
    staging (release/)
      processing release/r001
        detecting changes
        removing old build path
        assembling build folder
        build staged
        executing deploy script
        failure reported
        archiving build
      processing release/r002
        detecting changes
        no changes ... skipping
    production (main)
      processing main
        detecting changes
        removing old build path
        assembling build folder
        build staged
        executing deploy script
        success reported
        archiving build
```

## About Testing  

You should be testing your code.  And you should include testing in your CICD pipeline.  I just don't believe a CICD package should always take on that responsibility... at least, not alone.

Every developer and team have slightly different approaches to handling testing.  Generally speaking, CICD packages provide wrappers around testing frameworks.  And while that may _sound_ convenient, it's not.  The syntax sent to the test harness is generally hidden and cannot be altered.  And, the authors behind the CICD product have a never-ending responsibility to maintain those wrappers.  Asking the authors of the test framework to embrace a specific CICD product seems unfair since taking on that responsibility would cause their efforts to grow exponentially.

Every test framework I can think of is capable of being invoked via the command line.  And I'm fairly certain that you've done this with whatever product you prefer.  In my opinion, the most most useful path is to leverage that same knowledge and syntax to call upon that test product and parse the results.  I would even go so far is to say that I'm fairly certain you'll find ample syntax examples online to do this.

So, where am I going with this?  Good question.  I'm not entirely sure.  It really depends on what people need or want.  Maybe the solution is to simply add to the `/examples` folder with snippets showing how to call various test products.  Maybe I'll create a separate project dedicated to the never-ending question to just handle testing.  Honestly, I'll have to wait and see if there's an interest... or, heck, even if there is an interest in _this_ lil' project.

## Warranty  

In short, you're on your own.  While I will be more than happy to help brainstorm or look at syntax, the code contained in this repo is not guaranteed or covered under a warranty in any way.  It is provided as an experiment and a desire to inspire other developers.  The syntax within the `cicd.sh` script was intentionally written in the simplest and most verbose form possible, with tons of comments, so it may be understood and tweaked by even the newest developers.

## Limitataions, Concerns, To-Dos  

At the time of this writing, this repo is a "first draft" and has not been thoroughly tested in a true production environment.  My goal was to put it out into the world so I could brainstorm with other developers.  There are a ton of ideas floating around in my head but I've held back on trying to tackle all of them.  Here are just a few of my thoughts surrounding `cicd.sh`:
 
**Complex Paths**  
Need to figure out how to handle bizarre paths should someone add them to the `project.json`.  At the moment I'm not escaping spaces or any type of odd characters.  Not doing this could potentially cause the script to fail.  

**Testing Examples**  
Read my mini-rant above for more info on this.  

**Better Error Handling**  
This one I may need to wait on feedback for.  The script performs basic checks, for things like missing objects in the `project.json`, but I wonder if this is enough.  If the `cicd.sh` script is to remain simple to understand and work with, it cannot become bloated.  

**Incorporate Vault Storage**  
Add logic to tokenize the `-deploy` and `-data` folders so secrets and senstive information can be pulled from a secure key storage area or vault.  

## Contact Info  

Feel free to reach out if I can be of any assistance:

Fred Lackey  
[fred.lackey@gmail.com](mailto://fred.lackey@gmail.com)  
[http://fredlackey.com](http://fredlackey.com)  
