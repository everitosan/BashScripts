#!/bin/bash

# Version of the script
VERSION="0.0.1"

## Global colors
BLUE="\e[34m";
GREEN="\e[32m";
RED="\e[31m";
YELLOW="\e[33m"
PURPLE="\e[35m"
RESET="\e[0m";

# Supported versions
NODEJS="NodeJS";
RUST="Rust";

# Global variables
NEW_VERSION="";
PLATFORM="unknown";
ACTUAL_VERSION="unknown";
VERSION_FILE="unknown";
FORCE="";

function recognize_version {
  if [ -f  "package.json" ]; then
    PLATFORM="${NODEJS}";
    VERSION_FILE="package.json";
  fi
  if [ -f  "cargo.toml" ]; then
    PLATFORM="${RUST}";
    VERSION_FILE="cargo.toml";
  fi
}

function get_version {
  case "${PLATFORM}" in
    "${NODEJS}")
      get_node_version;
      ;;
    "${RUST}")
      get_rust_version;
      ;;
    *)
      echo -e "${YELLOW}Platform unknown${RESET}";
      exit 1;
      ;;
  esac 
}

function set_version {
  case "${PLATFORM}" in
    "${NODEJS}")
      set_node_version;
      ;;
    "${RUST}")
      set_rust_version;
      ;;
    *)
      echo -e "${YELLOW}Platform unknown${RESET}";
      exit 1;
      ;;
  esac 
}

# #######
# NODE JS
# #######
function get_node_version {
  ACTUAL_VERSION=$(cat "${VERSION_FILE}" | jq .version | sed 's/"//g' );
}

function set_node_version {
  sed -i "s/\"version\": \"${ACTUAL_VERSION}\"/\"version\": \"${NEW_VERSION}\"/g" "${VERSION_FILE}";
}

# #######
# Cargo
# #######

function get_rust_version {
  ACTUAL_VERSION=$(cat "${VERSION_FILE}" | grep version | awk '{ print $3 }' | sed 's/"//g' );
}

function set_rust_version {
  sed -i "s/version = \"${ACTUAL_VERSION}\"/version = \"${NEW_VERSION}\"/g" "${VERSION_FILE}";
}

# --------------------------------------------------------------------------------------------------------------- #

# Validates is new version is higher than te actual recognized
function validate_version {
  old_ifs="$IFS" # Save the current IFS value
  IFS='.' # Set IFS to '.'
  read -ra actual_v <<< "$ACTUAL_VERSION";  # Read the string into an array
  read -ra new_v <<< "$NEW_VERSION";  # Read the string into an array
  IFS="$old_ifs"; # Restore the old IFS value

  length=${#actual_v[@]};

  for (( i=0; i<${length}; i++ )); do
    av=$(("${actual_v[$i]}"))
    nv=$(("${new_v[$i]}"))
    # printf "Current index %d with value %s\n" $i "${new_v[$i]}"
    if [[ "$av" -gt "$nv" ]]; then
      echo -e "${YELLOW}
** Actual version ${ACTUAL_VERSION} is higher than ${NEW_VERSION},  use -f to avoid this check ${RESET}";
      exit 1;
    fi
  done
}

# Validates ther are no local changes in a pending commit
function validate_pending {
  pending_files=$(git status --untracked-files=no -s)
  if [[ ! -z $pending_files ]]; then
      echo -e "${YELLOW}
** You have pending changes to commit, use -f to avoid this check
    ${RESET}";
    exit 1;
  fi

}

function header {
  echo -e "${PURPLE}
███████████████
█▄─▀█▄─▄█▄─█─▄█
██─█▄▀─███▄─▄██
▀▄▄▄▀▀▄▄▀▀▄▄▄▀▀  

Version updater (${VERSION})${RESET}
";
}

function help {
  echo -e "  Flags:
    -v [version in x.x.x format]
    -f [force mode, avoid validations]
";
}

# #################
# 🚪 Main Function
# #################

function main {
  # ----> Intial project recognition
  recognize_version;
  get_version;
  echo -e "Platform file: ${GREEN}${VERSION_FILE}${RESET}";
  # ----> Validate version is higher
  if [[ -z "${FORCE}" ]]; then
    validate_version;
  else
    echo -e "${YELLOW}Avoiding valid version check ...${RESET}"; 
  fi
  # ----> Validate pending changes
  if [[ -z "${FORCE}" ]]; then
    validate_pending;
  else
    echo -e "${YELLOW}Avoiding pending commit check ...${RESET}"; 
  fi
  hastag=$(git tag -l | grep "${NEW_VERSION}")
  if [[ ! -z "${hastag}" ]]; then 
    git tag -d "v${NEW_VERSION}";
  fi
  echo -e "Moving to version: ${GREEN}${NEW_VERSION}${RESET}";
  set_version;
  git add "${VERSION_FILE}";
  git commit -m "version: set v${NEW_VERSION}"
  git tag "v${NEW_VERSION}";
}


header;
while getopts ":h :fv:" option; do
  case $option in
    v)
      NEW_VERSION=$OPTARG;
      ;;
    f)
      FORCE="t";
      ;;
    h)
      help;
      exit;;
    \?)
      help;
      exit;;
  esac
done


# ----> Validate an argument is passed
if [ $# -eq 0 ]; then
  help;
  exit 1;
fi

if [[ -z "${NEW_VERSION}" ]]; then
  help;
  exit 1;
fi

main;