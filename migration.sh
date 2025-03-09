#!/bin/bash

declare -a SRC_GIT_REPO=()
declare -a SRC_GIT_BRANCH=()
declare -a HELM_TEMPLATE_REPO=()
declare -a HELM_TEMPLATE_BRANCH=()
declare -a DEST_GIT_REPO=()
declare -a DEST_GIT_BRANCH=()
declare -a ENV_FILE_NAME

# Function to check if required variables are set
check_empty() {
    local var_name=$1
    local var_value=$2   
    if [ -z "$var_value" ]; then
        echo "Error: $var_name is required but empty"
        exit 1
    fi
}

# validate_url() {
#     local url="$1"
#     if [[ ! "$url" =~ ^https://[a-zA-Z0-9.-]+(/[a-zA-Z0-9._~:/?#\[\]@!$&\()*+,';=%-]*)?$ ]]; then
#         echo "Current value: $url"
#         return 1
#     fi
#     echo "$var_name validation successful"
#     return 0
# }

# Function to clone and checkout a repository
clone_and_checkout() {
    local repo_url=$1
    local branch=$2
    local dir_name=$3

    echo "Cloning repository: $repo_url"
    git clone "$repo_url" "$dir_name"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to clone repo $repo_url"
        return 1
    fi

    cd "$dir_name"
    echo "Checking out branch: $branch"
    git checkout "$branch"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to checkout repo $repo_url branch $branch"
        cd ..
        return 1
    fi
    cd ..
    return 0
}

# Function to commit and push changes to destination repository
commit_and_push_changes() {
    local repo_dir="DEST_REPO"
    local branch=${1:-main}  # Default to main if no branch specified
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')

    echo "Committing changes to destination repository..."
    
    # Change to destination repository directory
    cd "$repo_dir" || {
        echo "Error: Failed to change to directory $repo_dir"
        return 1
    }

    # Add migration timestamp to README
    echo -e "Migration date $timestamp" >> README.md || {
        echo "Error: Failed to update README.md"
        return 1
    }

    # Show repository status
    ls -la

    # Stage all changes
    git add * || {
        echo "Error: Failed to stage changes"
        return 1
    }

    # Commit changes
    git commit -m "Manually migration on date: $timestamp" || {
        echo "Error: Failed to commit changes"
        return 1
    }

    # Push changes
    git push --set-upstream origin "$branch" || {
        echo "Error: Failed to push changes to remote repository"
        return 1
    }

    echo "Successfully pushed changes to repository: $DEST_GIT_REPO"
    
    # Return to parent directory
    cd ..
    return 0
}

# Function to read and parse the env.cfn file
parse_config_file() {
    local file="${ENV_FILE_NAME}"
    
    # Check if file exists
    if [[ ! -f "$file" ]]; then
        echo "Error: $file not found"
        exit 1
    fi
    
    # Read file line by line
    while IFS=: read -r key value; do
        # Skip empty lines
        [[ -z "$key" ]] && continue
       
        # Remove leading/trailing whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        # echo $key
        # echo $value
        # Split values by semicolon
        IFS=';' read -ra value_array <<< "$value"

        # Store values in appropriate array based on key
        case "$key" in
            "SRC_GIT_REPO")
                #echo "${value_array[@]}"
                SRC_GIT_REPO=("${value_array[@]}")
                ;;
            "SRC_GIT_BRANCH")
                #echo "${value_array[@]}"
                SRC_GIT_BRANCH=("${value_array[@]}")
                ;;
            "HELM_TEMPLATE_REPO")
                HELM_TEMPLATE_REPO=("${value_array[@]}")
                ;;
            "HELM_TEMPLATE_BRANCH")
                HELM_TEMPLATE_BRANCH=("${value_array[@]}")
                ;;
            "DEST_GIT_REPO")
                DEST_GIT_REPO=("${value_array[@]}")
                ;;
            "DEST_GIT_BRANCH")
                DEST_GIT_BRANCH=("${value_array[@]}")
                ;;
        esac
    done < "$file"
}

# Function to display array contents
display_array() {
    local array_name=$1
    echo "Contents of $array_name:"
    eval "local length=\${#$array_name[@]}"
    for ((i=0; i<length; i++)); do
        eval "echo \"  [$i]: \${$array_name[$i]}\""
    done
    echo "---"
}

# Example usage with validation
validate_arrays() {
    if [[ ${#SRC_GIT_REPO[@]} -eq 0 ]]; then
            echo "Error: SRC_GIT_REPO repo value cannot be blank"
            return 1
    fi
    if [[ ${#SRC_GIT_REPO[@]} != ${#SRC_GIT_BRANCH[@]} ]]; then
            echo "Error: Array lengths don't match. $array has ${#arr[@]} elements, expected $base_length"
            return 1
    fi
    if [[ ${#HELM_TEMPLATE_REPO[@]} -eq 0 || ${#HELM_TEMPLATE_REPO[@]} -gt 1 ]]; then
                echo "Error: Template repo must have exactly one value"
            return 1
    fi
    if [[ ${#DEST_GIT_REPO[@]} -eq 0 || ${#DEST_GIT_REPO[@]} -gt 1 ]]; then
            echo "Error: Destination repo must have exactly one value"
            return 1
    fi
    return 0
}

# Clear the screen
clear

# Welcome message
echo "==================================================="
echo "Welcome to the Migration Process ,Please Provide Required Information"
echo "==================================================="
echo

read -p "Select single/mupltiple Repo(S/M): " MULTIPLE_SRC_REPO
MULTIPLE_SRC_REPO=${MULTIPLE_SRC_REPO:-M}
if [[ $(echo "$MULTIPLE_SRC_REPO" | awk '{print toupper($0)}') == "S" ]]; then
    # Collect Migration Information for single repo
    read -p "Enter Source Repository URL: " SRC_GIT_REPO
    read -p "Enter Source Repository Branch: " SRC_GIT_BRANCH
    SRC_GIT_BRANCH=${SRC_GIT_BRANCH:-main}
    read -p "Enter Template Repository URL: " HELM_TEMPLATE_REPO
    read -p "Enter Template Repository Branch: " HELM_TEMPLATE_BRANCH
    HELM_TEMPLATE_BRANCH=${HELM_TEMPLATE_BRANCH:-main}
    read -p "Enter Destination Repository URL: " DEST_GIT_REPO
    read -p "Enter Destination Repository Branch: " DEST_GIT_BRANCH
    DEST_GIT_BRANCH=${DEST_GIT_BRANCH:-main}
    # Display summary of collected information
    echo
    echo "==================================================="
    echo "User Input Summary:"
    echo "==================================================="
    echo "Source Repository URL: $SRC_GIT_REPO"
    echo "Source Repository Branch: $SRC_GIT_BRANCH"
    echo "Template Repository URL: $HELM_TEMPLATE_REPO"
    echo "Template Repository Branch: $HELM_TEMPLATE_BRANCH"
    echo "Destination Repository URL: $DEST_GIT_REPO"
    echo "Destination Repository Branch: $DEST_GIT_BRANCH"
    echo "==================================================="
    #Validate Information
    check_empty "Source Repository URL" "$SRC_GIT_REPO"
    check_empty "Source Repository Branch" "$SRC_GIT_BRANCH"
    check_empty "Template Repository URL" "$HELM_TEMPLATE_REPO"
    check_empty "Template Repository Branch" "$HELM_TEMPLATE_BRANCH"
    check_empty "Destination Repository URL" "$DEST_GIT_REPO"
    check_empty "Destination Repository Branch" "$DEST_GIT_BRANCH"
else
   read -p "Provide configuration FileName, Default file (env.cfg): " ENV_FILE_NAME
   ENV_FILE_NAME=${ENV_FILE_NAME:-env.cfg} 
   # Collect Migration Information for multiple repo
    parse_config_file
    echo
    echo "==================================================="
    echo "User Input Summary:"
    echo "==================================================="
    echo "SRC_GIT_REPO count: ${#SRC_GIT_REPO[@]}"
    echo "HELM_TEMPLATE_REPO count: ${#HELM_TEMPLATE_REPO[@]}"
    echo "DEST_GIT_REPO count: ${#DEST_GIT_REPO[@]}"
    display_array "SRC_GIT_REPO"
    display_array "SRC_GIT_BRANCH"
    display_array "HELM_TEMPLATE_REPO"
    display_array "HELM_TEMPLATE_BRANCH"
    display_array "DEST_GIT_REPO"
    display_array "DEST_GIT_BRANCH"
    echo "==================================================="
    # Run validation
    if validate_arrays; then
        echo "Array validation successful"
    else
        echo "Error: Arrays are not properly configured"
        exit 1
    fi

fi


# # URL Validation :
# if ! validate_url "$SRC_GIT_REPO"; then
#     exit 1
# fi
# if ! validate_url "$HELM_TEMPLATE_REPO"; then
#     exit 1
# fi
# if ! validate_url "$DEST_GIT_REPO"; then
#     exit 1
# fi

read -p "Confirm Migration Start (yes/no): " MIGRATION_START
if [[ $(echo "$MIGRATION_START" | awk '{print tolower($0)}') == "yes" ]]; then
    echo "Checkout the Source Code..."
    WORK_DIR="workspace"
    mkdir -p $WORK_DIR
    cd $WORK_DIR
    if [[ $(echo "$MULTIPLE_SRC_REPO" | awk '{print toupper($0)}') == "Y" ]]; then
        SRC_REPO="SRC_REPO"
        mkdir -p $SRC_REPO
        # Clone and checkout source repository
        for i in "${!SRC_GIT_REPO[@]}"; do
            repo="${SRC_GIT_REPO[$i]}"
            branch="${SRC_GIT_BRANCH[$i]}"
            echo "Repository: $repo"
            echo "Branch: $branch"
            repo_name1=$(basename "$repo" .git) 
            clone_and_checkout "$repo" "$branch" "$repo_name1" || exit 1
            mkdir -p $SRC_REPO/$repo_name1
            cp -r $repo_name1/* $SRC_REPO/$repo_name1
            rm -rf $repo_name1 
        done
    
        # Clone and checkout helm template repository
        for i in "${!HELM_TEMPLATE_REPO[@]}"; do
            repo="${HELM_TEMPLATE_REPO[$i]}"
            branch="${HELM_TEMPLATE_BRANCH[$i]}"
            echo "Template Repository: $repo"
            echo "Template Branch: $branch"
            clone_and_checkout "$repo" "$branch" "HELM_TEMPLATE_REPO" || exit 1
        done
    
        # Clone and checkout destination repository
        for i in "${!DEST_GIT_REPO[@]}"; do
            repo="${DEST_GIT_REPO[$i]}"
            branch="${DEST_GIT_BRANCH[$i]}"
            echo "Destination Repository: $repo"
            echo "Destination Branch: $branch"
            clone_and_checkout "$repo" "$branch" "DEST_REPO" || exit 1
        done
    else
        # Clone and checkout source repository
        clone_and_checkout "$SRC_GIT_REPO" "$SRC_GIT_BRANCH" "SRC_REPO" || exit 1

        # Clone and checkout helm template repository
        clone_and_checkout "$HELM_TEMPLATE_REPO" "$HELM_TEMPLATE_BRANCH" "HELM_TEMPLATE_REPO" || exit 1

        # Clone and checkout destination repository
        clone_and_checkout "$DEST_GIT_REPO" "$DEST_GIT_BRANCH" "DEST_REPO" || exit 1
    fi

    echo "All repositories successfully cloned and checked out"
    echo "==================================================="
    echo "Proceeding with Migration Process..."
    python3 convert_ose_to_eks.py
    echo "Conversion Completed Sucessfully"
    commit_and_push_changes "$DEST_GIT_BRANCH"
    echo "Migration Process completed successfully!"
    echo "=======================THANK YOU============================"
else
    echo "Migration Process cancelled."
    exit 0
fi

