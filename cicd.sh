#!/bin/bash

main() {

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
    echo "    source : $SOURCE_REPO"

    #region Clone the source repo to a locally for future comparisons
    if [ -d "${SOURCE_PATH}/_" ]; then
      echo "             ... updating"
      eval "git -C \"${SOURCE_PATH}/_\" pull &> /dev/null"
    else
      eval "mkdir -p \"${SOURCE_PATH}/__\""
      if [ -d "${SOURCE_PATH}/__/${SOURCE_FOLDER}" ]; then
        echo "             ... cleaning"
        eval "rm -rf \"${SOURCE_PATH}/__/${SOURCE_FOLDER}\""
      fi
      echo "             ... fetching"
      eval "git -C \"${SOURCE_PATH}/__\" clone $SOURCE_REPO &> /dev/null"
      eval "mv \"${SOURCE_PATH}/__/${SOURCE_FOLDER}\" \"${SOURCE_PATH}/_\""
      eval "rm -rf \"${SOURCE_PATH}/__\""
    fi
    #endregion

    echo "    data   : $DATA_REPO"

    #region Clone the data repo to a locally for future comparisons
    if [ -d "${DATA_PATH}/_" ]; then
      echo "             ... updating"
      # eval "cd \"${DATA_PATH}/_\" & git pull &> /dev/null"
      eval "git -C \"${DATA_PATH}/_\" pull &> /dev/null"
    else
      eval "mkdir -p \"${DATA_PATH}/__\""
      if [ -d "${DATA_PATH}/__/${DATA_FOLDER}" ]; then
        echo "             ... cleaning"
        eval "rm -rf \"${DATA_PATH}/__/${DATA_FOLDER}\""
      fi
      echo "             ... fetching"
      # eval "git -C \"${DATA_PATH}/__\" clone --quiet $DATA_REPO"
      eval "git -C \"${DATA_PATH}/__\" clone $DATA_REPO &> /dev/null"
      eval "mv \"${DATA_PATH}/__/${DATA_FOLDER}\" \"${DATA_PATH}/_\""
      eval "rm -rf \"${DATA_PATH}/__\""
    fi
    #endregion

    echo "    deploy : $DEPLOY_REPO"

    #region Clone the deploy repo locally for future comparisons
    if [ -d "${DEPLOY_PATH}/_" ]; then
      echo "             ... updating"
      eval "git -C \"${DEPLOY_PATH}/_\" pull &> /dev/null"
    else
      eval "mkdir -p \"${DEPLOY_PATH}/__\""
      if [ -d "${DEPLOY_PATH}/__/${DEPLOY_FOLDER}" ]; then
        echo "             ... cleaning"
        eval "rm -rf \"${DEPLOY_PATH}/__/${DEPLOY_FOLDER}\""
      fi
      echo "             ... fetching"
      eval "git -C \"${DEPLOY_PATH}/__\" clone $DEPLOY_REPO &> /dev/null"
      eval "mv \"${DEPLOY_PATH}/__/${DEPLOY_FOLDER}\" \"${DEPLOY_PATH}/_\""
      eval "rm -rf \"${DEPLOY_PATH}/__\""
    fi
    #endregion

    # Locate all potential source branches
    REMOTE_BRANCHES=()
    eval "$(git -C ${SOURCE_PATH}/_ for-each-ref --shell --format='REMOTE_BRANCHES+=(%(refname))' refs/remotes/)"

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

      #region Ensure the branches for data & deploy are concrete without wildcards
      if [[ $ENV_BRANCH_DATA == */ ]]; then
          echo "      data branch not concrete ... skipping"
          continue
      fi
      if [[ $ENV_BRANCH_DEPLOY == */ ]]; then
          echo "      deploy branch not concrete ... skipping"
          continue
      fi
      #endregion

      # Create a fully-qualified prefix to account for branch name patterns
      PREFIX="refs/remotes/origin/"
      BRANCH_PREFIX="$PREFIX""$ENV_BRANCH_SOURCE"

      #region Determine the relevant branches based on the name pattern 
      FILTERED=()
      for REMOTE in "${REMOTE_BRANCHES[@]}"; do

        if [[ $ENV_BRANCH_SOURCE == */ ]]; then
          if [[ $REMOTE = $BRANCH_PREFIX* ]]; then
            FILTERED[${#FILTERED[@]}]=$REMOTE
          fi
        else
          if [ $REMOTE = $BRANCH_PREFIX ]; then
            FILTERED[${#FILTERED[@]}]=$REMOTE
          fi
        fi

      done
      #endregion

      # Loop through the filtered repos from the pattern matching (ie "feature/*", etc.)
      for FNAME in "${FILTERED[@]}"; do

        # Strip the prefix from the full branch name
        WORK_DIR=${FNAME#"$PREFIX"}
        echo "      processing $WORK_DIR"

        # Create a local copy of the repo for each branch so they can be monitored individually for changes
        REPO_PATH="${SOURCE_PATH}/${WORK_DIR}"
        if [ ! -d "$REPO_PATH" ]; then
          echo "        creating working area"

          # Create the parent folder path in preparation for the cp & clone commands
          if [[ $WORK_DIR} == *\/* ]]; then
            PARENT=$(dirname $REPO_PATH)
            eval "mkdir -p $PARENT"
            if [ ! -d $PARENT ]; then
              echo "        parent folder not created ... skipping"
              continue
            fi
          fi

          # Branch copy is made from the master copy.  Branch is checked out in the new location.          
          eval "cp -r ${SOURCE_PATH}/_ $REPO_PATH"
          eval "git -C $REPO_PATH fetch --quiet"
          eval "git -C $REPO_PATH checkout $WORK_DIR &> /dev/null"

          if [ ! -d "$REPO_PATH" ]; then
              echo "        work area not created ... skipping"
              continue
          fi 
        fi

        # At this point the branch-specific copy would either:
        #   a: has just been created; or,
        #   b: is existing and possibly stale.

        # TODO: PERFORM A PULL AFTER A SUCCESSFUL BUILD TO ENSURE THE FOLDER IS UP TO DATE!

        # Fetch the repo's signatures and grab the checksums for the local and remote copies
        echo "        detecting changes"
        eval "git -C $REPO_PATH fetch --quiet &> /dev/null"
        LOCAL=$(git -C $REPO_PATH rev-parse HEAD);
        REMOTE=$(git -C $REPO_PATH rev-parse @{u});

        # Skip this branch's checksums are matching the server then no changes have been made.  Skip it.
        if [ $LOCAL == $REMOTE ]; then
          echo "        no changes ... skipping"
          continue
        fi

        # NOTE:
        # Originally used a block date for the build folder.  May add this later as an archive step.

        # Build path is located parallel to the branch folders in the local storage area for the source repo
        BUILD_DIR="_build"
        BUILD_PATH="${SOURCE_PATH}/${BUILD_DIR}"

        #region Remove the build folder if it was leftover from a crash or not properly archived
        if [ -d "$BUILD_PATH" ]; then
          echo "        removing old build path"
          eval "rm -rf $BUILD_PATH"
          if [ -d "$BUILD_PATH" ]; then
            echo "        build path not removed ... skipping"
            continue
          fi
        fi
        #endregion

        #region -- FOLDER VALIDATION --
        if [ ! -d "${DEPLOY_PATH}/_/${ENVIRONMENT_NAME}" ]; then
          echo "        deployment folder missing ... skipping"
          continue
        fi
        if [ ! -d "${DATA_PATH}/_/${ENVIRONMENT_NAME}" ]; then
          echo "        data folder missing ... skipping"
          continue
        fi
        #endregion

        echo "        assembling build folder"

        # Files are assembled under the deploy folder.  
        # Environment-specific data files are overlayed and overwritten if needed.
        # Deployment scripts (also environment-specific) are overlayed into the root.

        eval "mkdir -p $BUILD_PATH"
        eval "cp -r $REPO_PATH $BUILD_PATH/deploy"
        eval "rsync -a -I ${DATA_PATH}/_/${ENVIRONMENT_NAME}/ $BUILD_PATH/deploy/"
        eval "rsync -a -I ${DEPLOY_PATH}/_/${ENVIRONMENT_NAME}/ $BUILD_PATH/"

        # The standard script "deploy.sh" must be supplied by the scripts.  It will be in the root of the build folder.          
        if [ ! -f "$BUILD_PATH/deploy.sh" ]; then
          echo "        deploy.sh not found ... skipping"
          continue
        fi

        echo "        build staged"
        echo "        executing deploy script"

        # Import the build script
        source "$BUILD_PATH/deploy.sh"

        if deploy-sh; then
          echo "        success reported"
          ARCHIVE_BASE_PATH=$ARCHIVES_SUCCESS_PATH
          ARCHIVE_EXCLUDES=$ARCHIVES_SUCCESS_EXCLUDES
        else
          echo "        failure reported"
          ARCHIVE_BASE_PATH=$ARCHIVES_FAILURE_PATH
          ARCHIVE_EXCLUDES=$ARCHIVES_FAILURE_EXCLUDES
        fi

        # Update the local hope to prevent the same changes from triggering another pull
        eval "git -C $REPO_PATH pull --quiet &> /dev/null"

        if [ "$ARCHIVE_BASE_PATH" == "null" ]; then
          echo "        no archive path set"
          continue
        else
          echo "        archiving build"
        fi

        ARCHIVE_DIR="$*$(date +"%Y%m%d%H%M%S")"
        ARCHCIVE_PATH="$ARCHIVE_BASE_PATH/$SOURCE_FOLDER/$WORK_DIR/$ARCHIVE_DIR"

        if [ "$ARCHIVE_EXCLUDES" == "null" ]; then
          ARCHIVE_CMD="rsync -arv --no-links --quiet $BUILD_PATH/ $ARCHCIVE_PATH"
        else
          ARCHIVE_CMD="rsync -arv --no-links --quiet --exclude={$ARCHIVE_EXCLUDES} $BUILD_PATH/ $ARCHCIVE_PATH"
        fi

        eval "mkdir -p $ARCHIVE_BASE_PATH/$SOURCE_FOLDER/$WORK_DIR"
        if [ ! -d "$ARCHIVE_BASE_PATH/$SOURCE_FOLDER/$WORK_DIR" ]; then
          echo "        archive folder not ready ... skipping"
          continue
        fi

        eval "$ARCHIVE_CMD"
        if [ ! -d "$ARCHCIVE_PATH" ]; then
          echo "        archive not created"
        fi

      done

    done

  done

}

main