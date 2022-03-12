#!/bin/bash

stage_repo() {

  # Local copies of each repo are maintained to minimize calls to the source control server.

  REPO_URL=$1
  LOCAL_PATH=$2
  FOLDER_NAME="${REPO_URL##*/}"

  if [ -d "$LOCAL_PATH/_temp" ]; then
    echo "             ... cleaning"
    eval "rm -rf \"$LOCAL_PATH/_temp\""
  fi

  if [ -d "$LOCAL_PATH/_" ]; then
    echo "             ... updating"
    eval "git -C \"$LOCAL_PATH/_\" pull &> /dev/null"
    return 0
  fi

  eval "mkdir -p \"$LOCAL_PATH/_temp\""
  echo "             ... fetching"
  eval "git -C \"$LOCAL_PATH/_temp\" clone $REPO_URL &> /dev/null"

  if [ ! -d "$LOCAL_PATH/_temp/$FOLDER_NAME" ]; then
    return 1
  fi

  eval "mv \"$LOCAL_PATH/_temp/$FOLDER_NAME\" \"$LOCAL_PATH/_\""
  eval "rm -rf \"$LOCAL_PATH/_temp\""

  if [ ! -d "$LOCAL_PATH/_" ]; then
    return 1
  fi

  return 0

}
stage_branches() {

  # Local copies of all remote branches allow for quick comparisons and copy operations.

  LOCAL_PATH=$1
  PREFIX="refs/remotes/origin/"

  echo "             ... staging"

  if [ ! -d "$LOCAL_PATH/_" ]; then
    echo "             ... master not found ... skipping"
    return 1
  fi

  REMOTE_BRANCHES=()
  eval "$(git -C $LOCAL_PATH/_ for-each-ref --shell --format='REMOTE_BRANCHES+=(%(refname))' refs/remotes/)"

  for REMOTE in "${REMOTE_BRANCHES[@]}"; do

    BRANCH_NAME=${REMOTE#"$PREFIX"}
    if [ $BRANCH_NAME == "HEAD" ]; then
      continue
    fi
  
    BRANCH_PATH="$LOCAL_PATH/$BRANCH_NAME"
    if [ -d "$BRANCH_PATH" ]; then
      continue
    fi
  
    PARENT_PATH=$(dirname $BRANCH_PATH)
    eval "mkdir -p $PARENT_PATH"
    if [ ! -d "$PARENT_PATH" ]; then
      echo "             ... cannot create storage ... skipping"
      return 1
    fi
  
    eval "cp -r $LOCAL_PATH/_ $BRANCH_PATH"
    if [ ! -d "$BRANCH_PATH" ]; then
      echo "             ... local branch not created ... skipping"
      return 1
    fi

    eval "git -C $BRANCH_PATH fetch --quiet"
    eval "git -C $BRANCH_PATH checkout $BRANCH_NAME &> /dev/null"

  done

  return 0

}
assemble_build() {

  # Source, -data, and -deploy repos are merged to create a build folder.

  echo "        aseembling build"

  ENVIRONMENT_NAME=$1
  SOURCE_BRANCH_PATH=$2
  SOURCE_BRANCH_NAME=$3
  DATA_PATH=$4
  DATA_BRANCH=$5
  DEPLOY_PATH=$6
  DEPLOY_BRANCH=$7

  GIT_EXCLUDES=".dropbox,.DS_Store,.git,_gsdata_,.idea,node_modules,.vscode"

  # If data branch is prefixed 
  if [[ $DATA_BRANCH == */ ]]; then
    # ... then match with the source branch
    DATA_PATH_FULL="$DATA_PATH/$SOURCE_BRANCH_NAME"
  else
    # otherwise use concrete name
    DATA_PATH_FULL="$DATA_PATH/$DATA_BRANCH"
  fi

  if [ ! -d "$DATA_PATH_FULL" ]; then
    echo "        data branch not staged"
    return 1
  fi
  if [ ! -d "$DATA_PATH_FULL/$ENVIRONMENT_NAME" ]; then
    echo "        data branch not intact"
    return 1
  fi

  # If deploy branch is prefixed 
  if [[ $DEPLOY_BRANCH == */ ]]; then
    # ... then match with the source branch
    DEPLOY_PATH_FULL="$DEPLOY_PATH/$SOURCE_BRANCH_NAME"
  else
    # otherwise use concrete name
    DEPLOY_PATH_FULL="$DEPLOY_PATH/$DEPLOY_BRANCH"
  fi

  if [ ! -d "$DEPLOY_PATH_FULL" ]; then
    echo "        deploy branch not staged"
    return 1
  fi
  if [ ! -d "$DEPLOY_PATH_FULL/$ENVIRONMENT_NAME" ]; then
    echo "        deploy branch not intact"
    return 1
  fi

  BUILD_ROOT_PATH="$SOURCE_BRANCH_PATH"
  BUILD_ROOT_PATH=${BUILD_ROOT_PATH%"$SOURCE_BRANCH_NAME"}
  
  TEMP_PATH="$BUILD_ROOT_PATH""_temp"
  BUILD_PATH="$BUILD_ROOT_PATH""_build"
  
  if [ -d "$TEMP_PATH" ]; then
    echo "        remove old temp path"
    eval "rm -rf $TEMP_PATH"
    if [ -d "$TEMP_PATH" ]; then
      echo "        temp path not removed"
      return 1
    fi
  fi

  if [ -d "$BUILD_PATH" ]; then
    echo "        removing old build path"
    eval "rm -rf $BUILD_PATH"
    if [ -d "$BUILD_PATH" ]; then
      echo "        build path not removed"
      return 1
    fi
  fi

  # Copy the branch being deployed to a temp path for updating
  eval "cp -r $SOURCE_BRANCH_PATH $TEMP_PATH"
  if [ ! -d "$TEMP_PATH" ]; then
    echo "        build path not created"
    return 1
  fi

  # Pull the latest changes for the branch and remove git folder
  echo "        fetch changes"
  eval "git -C $TEMP_PATH pull --quiet &> /dev/null"
  eval "rm -rf $TEMP_PATH/.git &> /dev/null"

  # Creat the build folder
  eval "mkdir -p $BUILD_PATH"

  # Copy the updated source code from the temp folder into the _build/deploy folder
  echo "        copy updated source"
  eval "cp -r $TEMP_PATH $BUILD_PATH/deploy"

  # Merge the environment-specific data into the _build/deploy folder
  echo "        update data"
  eval "git -C $DATA_PATH/$SOURCE_BRANCH_NAME pull --quiet &> /dev/null"
  echo "        merge data"
  eval "rsync -a -I --exclude={$GIT_EXCLUDES} $DATA_PATH_FULL/$ENVIRONMENT_NAME/ $BUILD_PATH/deploy/"

  # Merge the environment-specific deploy scripts into the root of the _build folder
  echo "        update deploy scripts"
  eval "git -C $DEPLOY_PATH/$SOURCE_BRANCH_NAME pull --quiet &> /dev/null"
  echo "        merge deploy scripts"
  eval "rsync -a -I --exclude={$GIT_EXCLUDES} $DEPLOY_PATH_FULL/$ENVIRONMENT_NAME/ $BUILD_PATH/"

  return 0

}
deploy_build() {

  # Environment-specific deploy.sh script is called to perform custom deployment steps.

  echo "        deploying build"

  SOURCE_BRANCH_PATH=$1

  if [ ! -d "$SOURCE_BRANCH_PATH/_build/deploy" ]; then
    echo "        build not staged"
    return 1
  fi
  if [ ! -f "$SOURCE_BRANCH_PATH/_build/deploy.sh" ]; then
    echo "        deploy script missing"
    return 1
  fi

  source "$SOURCE_BRANCH_PATH/_build/deploy.sh"

  if deploy-sh; then
    echo "        success reported"
    return 0
  else
    echo "        failure reported"
    return 1
  fi

}
archive_build() {

  # Builds are optionally archived upon success, failure, or either.

  BUILD_PATH=$1
  ARCHIVE_BASE_PATH=$2
  ARCHIVE_EXCLUDES=$3

  echo "        archiving build"

  ARCHIVE_DATE=$(date +"%Y%m%d%H%M%S")
  ARCHIVE_PATH="$ARCHIVE_BASE_PATH/$ARCHIVE_DATE"

  if [ "$ARCHIVE_EXCLUDES" == "null" ]; then
    ARCHIVE_CMD="rsync -arv --no-links --quiet $BUILD_PATH/ $ARCHIVE_PATH"
  else
    ARCHIVE_CMD="rsync -arv --no-links --quiet --exclude={$ARCHIVE_EXCLUDES} $BUILD_PATH/ $ARCHIVE_PATH"
  fi

  # echo "ARCHIVE_CMD $ARCHIVE_CMD"
  # return 1

  if [ ! -d $BUILD_PATH ]; then
    echo "        build path missing"
    return 1
  fi

  eval "mkdir -p $ARCHIVE_BASE_PATH"
  if [ ! -d "$ARCHIVE_BASE_PATH" ]; then
    echo "        archive folder not ready"
    return 1
  fi

  eval "$ARCHIVE_CMD"
  if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "        archive not created"
    return 1
  fi

  return 0

}
update_branch() {

  # Local branch copy is updated after a build to ensure the current changes to not trigger an additional build.

  echo "        updating local branch"

  eval "git -C $BRANCH_PATH fetch --quiet &> /dev/null"
  LOCAL=$(git -C $BRANCH_PATH rev-parse HEAD);
  REMOTE=$(git -C $BRANCH_PATH rev-parse @{u});

  if [ $LOCAL == $REMOTE ]; then
    echo "        no changes detected"
    return 1
  fi

  eval "git -C $BRANCH_PATH pull --quiet &> /dev/null"
  LOCAL=$(git -C $BRANCH_PATH rev-parse HEAD);
  REMOTE=$(git -C $BRANCH_PATH rev-parse @{u});

  if [ $LOCAL == $REMOTE ]; then
    return 0
  else
    return 1
  fi

}
process_changes() {

  # Detect changes, process build, archive build (if requested), and update the branch.

  ENVIRONMENT_NAME=$1
  SOURCE_PATH=$2
  SOURCE_BRANCH=$3
  DATA_PATH=$4
  DATA_BRANCH=$5
  DEPLOY_PATH=$6
  DEPLOY_BRANCH=$7
  ARCHIVES_SUCCESS_PATH=$8 
  ARCHIVES_SUCCESS_EXCLUDES=$9 
  ARCHIVES_FAILURE_PATH=${10}
  ARCHIVES_FAILURE_EXCLUDES=${11}

  PREFIX="refs/remotes/origin/"

  REMOTE_BRANCHES=()
  eval "$(git -C $SOURCE_PATH/_ for-each-ref --shell --format='REMOTE_BRANCHES+=(%(refname))' refs/remotes/)"

  for REMOTE in "${REMOTE_BRANCHES[@]}"; do

    SHORT_BRANCH_NAME=${REMOTE#"$PREFIX"}

    if [ $SHORT_BRANCH_NAME == "HEAD" ]; then
      continue
    fi

    PREFIX="refs/remotes/origin/"
    FULL_BRANCH_NAME="$PREFIX""$SOURCE_BRANCH"

    # Skip any branches not matching the requested prefix or name
    if [[ $SOURCE_BRANCH == */ ]]; then
      if [[ $REMOTE != $FULL_BRANCH_NAME* ]]; then
        continue
      fi
    else
      if [ $REMOTE != $FULL_BRANCH_NAME ]; then
        continue
      fi
    fi

    echo "      processing $SHORT_BRANCH_NAME"

    BRANCH_PATH="$SOURCE_PATH/$SHORT_BRANCH_NAME"
    if [ ! -d $BRANCH_PATH ]; then
      echo "      not staged ... skipping"
      continue
    fi

    eval "git -C $BRANCH_PATH fetch --quiet &> /dev/null"
    LOCAL=$(git -C $BRANCH_PATH rev-parse HEAD);
    REMOTE=$(git -C $BRANCH_PATH rev-parse @{u});

    # Skip this branch's checksums are matching the server then no changes have been made.  Skip it.
    if [ $LOCAL == $REMOTE ]; then
      echo "        no changes ... skipping"
      continue
    else
      echo "        changes detected"
    fi

    if assemble_build $ENVIRONMENT_NAME $BRANCH_PATH $SHORT_BRANCH_NAME $DATA_PATH $ENV_BRANCH_DATA $DEPLOY_PATH $ENV_BRANCH_DEPLOY; then
      echo "        build assembled"
    else
      echo "        build failed ... skipping"
      continue
    fi

    if deploy_build $SOURCE_PATH; then
      echo "        deployed"
      ARCHIVE_PATH=$ARCHIVES_SUCCESS_PATH
      ARCHIVE_EXCLUDES=$ARCHIVES_SUCCESS_EXCLUDES
    else
      echo "        deployment failed"
      ARCHIVE_PATH=$ARCHIVES_FAILURE_PATH
      ARCHIVE_EXCLUDES=$ARCHIVES_FAILURE_EXCLUDES
    fi    

    # Failure when archiving must NOT fail the build or prevent branch update!
    if [ "$ARCHIVE_PATH" == "null" ]; then
      echo "        no archive path set"
    else 
      if archive_build $BUILD_PATH $ARCHIVE_PATH $ARCHIVE_EXCLUDES; then
        echo "        archive complete"
      else
        echo "        archive failed"
      fi   
    fi

    # Update the branch to ensure this current update will not trigger another build.
    if update_branch $BRANCH_PATH; then
        echo "        local branch updated"
    else
        echo "        local branch update failed"
        return 1
    fi

  done

  return 0
}

main() {

  # The main function validates / loads the definition file and then invoke the process per environment.

  local SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
  local SCRIPT_ROOT=$(dirname $SCRIPT_PATH)
  local PROJECTS_FILE="$SCRIPT_ROOT/projects.json"

  if [ ! -f $PROJECTS_FILE ]; then
    echo "Project file missing.  Cannot continue."
    return 1
  fi

  for PROJECT in $(jq '. | to_entries | .[].key' projects.json); do

    # Strip quotes from jq string
    PROJECT_NAME=${PROJECT%\"}
    PROJECT_NAME=${PROJECT_NAME#\"}

    # Pull the three main data blobs from the projects.json file
    REPOS_DATA=$(jq ".[$PROJECT].repos" projects.json)
    FOLDERS_DATA=$(jq ".[$PROJECT].folders" projects.json)
    ENVIRONMENTS_DATA=$(jq ".[$PROJECT].environments" projects.json)

    #region -- BLOB VALIDATION --
    if [ "$REPOS_DATA" == "null" ]; then
      echo "  Repo data not found.  Skipping."
      continue
    fi

    if [ "$FOLDERS_DATA" == "null"  ]; then
      echo "  Folders data not found.  Skipping."
      continue
    fi

    if [ "$ENVIRONMENTS_DATA" == null ]; then
      echo "  Environments data not found.  Skipping."
      continue
    fi
    #endregion

    # Extract the repos from the blobs
    SOURCE_REPO=$(jq -n "$REPOS_DATA" | jq .source | tr -d '"')
    DATA_REPO=$(jq -n "$REPOS_DATA" | jq .data | tr -d '"')
    DEPLOY_REPO=$(jq -n "$REPOS_DATA" | jq .deploy | tr -d '"')

    # Grab the git project name since the project name can be anything
    SOURCE_FOLDER="${SOURCE_REPO##*/}"
    DATA_FOLDER="${DATA_REPO##*/}"
    DEPLOY_FOLDER="${DEPLOY_REPO##*/}"

    # Extract the paths from the blobs
    SOURCE_PATH=$(jq -n "$FOLDERS_DATA" | jq .source | tr -d '"')
    DATA_PATH=$(jq -n "$FOLDERS_DATA" | jq .data | tr -d '"')
    DEPLOY_PATH=$(jq -n "$FOLDERS_DATA" | jq .deploy | tr -d '"')

    #region -- PATH VALIDATION --
    if [[ "$SOURCE_REPO" == "$DATA_REPO" || "$SOURCE_REPO" == "$DEPLOY_REPO" || "$DATA_REPO" == "$DEPLOY_REPO" ]]; then
      echo "  All repos must be different.  Skipping."
      continue
    fi
    if [[ "$SOURCE_PATH" == "$DATA_PATH" || "$SOURCE_PATH" == "$DEPLOY_PATH" || "$DATA_PATH" == "$DEPLOY_PATH" ]]; then
      echo "  All paths must be different.  Skipping."
      continue
    fi
    #endregion

    echo "$PROJECT_NAME"
    echo "  Folders:"
    echo "    source : $SOURCE_PATH"
    echo "    data   : $DATA_PATH"
    echo "    deploy : $DEPLOY_PATH"
    echo "  Repos:"

    #region Clone the repos locally
    echo "    source : $SOURCE_REPO"
    if ! stage_repo "$SOURCE_REPO" "$SOURCE_PATH"; then
      echo "             ... not retrieved ... skipping"
      continue
    fi
    if ! stage_branches "$SOURCE_PATH"; then
      echo "             ... not staged ... skipping"
      continue
    fi
    
    echo "    data   : $DATA_REPO"
    if ! stage_repo "$DATA_REPO" "$DATA_PATH"; then
      echo "             ... not retrieved ... skipping"
      continue
    fi
    if ! stage_branches "$DATA_PATH"; then
      echo "             ... not staged ... skipping"
      continue
    fi

    echo "    deploy : $DEPLOY_REPO"
    if ! stage_repo "$DEPLOY_REPO" "$DEPLOY_PATH"; then
      echo "             ... not retrieved ... skipping"
      continue
    fi
    if ! stage_branches "$DEPLOY_PATH"; then
      echo "             ... not staged ... skipping"
      continue
    fi
    #endregion

    # Loop through each of the project's declared environments 
    echo "  Environments:"
    for ENVIRONMENT in $(jq -n "$ENVIRONMENTS_DATA" | jq '. | to_entries | .[].key'); do
      
      # Strip the quotes from the jq string
      ENVIRONMENT_NAME=${ENVIRONMENT%\"}
      ENVIRONMENT_NAME=${ENVIRONMENT_NAME#\"}

      # Load the environment blob (will probably be used for adding other parameters)
      ENVIRONMENT_DATA=$(jq -n "$ENVIRONMENTS_DATA" | jq ".[$ENVIRONMENT]" )

      # Pull the environment's branches blob from the environment blob
      ENVIRONMENT_BRANCH_DATA=$(jq -n "$ENVIRONMENT_DATA" | jq ".branches" )

      # Determine the branch to be used for each of the three repos
      ENV_BRANCH_SOURCE=$(jq -n "$ENVIRONMENT_BRANCH_DATA" | jq .source | tr -d '"')
      ENV_BRANCH_DATA=$(jq -n "$ENVIRONMENT_BRANCH_DATA" | jq .data | tr -d '"')
      ENV_BRANCH_DEPLOY=$(jq -n "$ENVIRONMENT_BRANCH_DATA" | jq .deploy | tr -d '"')

      # Pull the environment's archives blob from the environment blob
      ENVIRONMENT_ARCHIVES_DATA=$(jq -n "$ENVIRONMENT_DATA" | jq ".archives" )

      # Pull the archive info for successful builds
      ARCHIVES_SUCCESS_DATA=$(jq -n "$ENVIRONMENT_ARCHIVES_DATA" | jq ".success" )
      ARCHIVES_SUCCESS_PATH=$(jq -n "$ARCHIVES_SUCCESS_DATA" | jq .path | tr -d '"')
      ARCHIVES_SUCCESS_EXCLUDES=$(jq -n "$ARCHIVES_SUCCESS_DATA" | jq .excludes | tr -d '"')

      # Pull the archive info for failed builds
      ARCHIVES_FAILURE_DATA=$(jq -n "$ENVIRONMENT_ARCHIVES_DATA" | jq ".failure" )
      ARCHIVES_FAILURE_PATH=$(jq -n "$ARCHIVES_FAILURE_DATA" | jq .path | tr -d '"')
      ARCHIVES_FAILURE_EXCLUDES=$(jq -n "$ARCHIVES_FAILURE_DATA" | jq .excludes | tr -d '"')

      echo "    $ENVIRONMENT_NAME ($ENV_BRANCH_SOURCE)"

      #region Ensure the branches for data & deploy are appropriate for the source
      if [[ $ENV_BRANCH_DATA == */ && $ENV_BRANCH_SOURCE != */  ]]; then
          echo "      data branch prefixed without source ... skipping"
          continue
      fi
      if [[ $ENV_BRANCH_DATA == */ && $ENV_BRANCH_SOURCE != $ENV_BRANCH_DATA  ]]; then
          echo "      data branch source mismatch ... skipping"
          continue
      fi
      if [[ $ENV_BRANCH_DEPLOY == */ && $ENV_BRANCH_SOURCE != */ ]]; then
          echo "      deploy branch prefixed without source ... skipping"
          continue
      fi
      if [[ $ENV_BRANCH_DEPLOY == */ && $ENV_BRANCH_SOURCE != $ENV_BRANCH_DEPLOY ]]; then
          echo "      deploy branch source mismatch ... skipping"
          continue
      fi
      #endregion

      process_changes $ENVIRONMENT_NAME $SOURCE_PATH $ENV_BRANCH_SOURCE $DATA_PATH $ENV_BRANCH_DATA $DEPLOY_PATH $ENV_BRANCH_DEPLOY $ARCHIVES_SUCCESS_PATH $ARCHIVES_SUCCESS_EXCLUDES $ARCHIVES_FAILURE_PATH $ARCHIVES_FAILURE_EXCLUDES

    done

  done

}

main