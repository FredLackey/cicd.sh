# Example Data Repo (Empty Version)

This folder is probably the least interesting and most self-explanatory of the entire project.  It contains an example layout of your `-data` repo.  Just like the `-deploy` repo, this one also contains folders named after the target deployment environments.  And, just like the `-deploy` repo, the contents of these folders what is merged during the build process.  Anything you place in the root (`/`) of this repo, such as this `README.md` file, is ignored.

## Anything Goes  

Not much can be said about the contents of the environment-specific folders.  Structure the contents of each folder using the same folder structure you would use in the repo of the application your developing.  Whatever environment-specific files you need a runtime just stick them in this repo.

## Root is Not Root  

Remember that the **root** of the `-data` repo is ignored during the build process.  For all intents and purposes, the chosen environment-specific folder is essentially the root.  So, if you need a file like `.env` to appear in the root of your application during the build process, that file goes in the environment-specific folder.

## Child Folders  

Creating a child / grandchild folder structure, within each environment-specific folder, is an ideal way to include environment-specific files in your application.  Remember, the folders are _merged_ during the build process.  For example, if your application needed seed files within a certain path...

```bash
/src/data/seeds/index.js
/src/data/seeds/mytypes.js
/src/data/seeds/myobjects.js
```

... you would locate them _here_ for the build going to the **development** target ...

```bash
/development/src/data/seeds/index.js
/development/src/data/seeds/mytypes.js
/development/src/data/seeds/myobjects.js
```

... and additional copies for the _other_ environments, such as **production** ...

```bash
/production/src/data/seeds/index.js
/production/src/data/seeds/mytypes.js
/production/src/data/seeds/myobjects.js
```
