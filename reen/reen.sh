#!/bin/bash

## Global variables
DEST="";
SOURCE_FILE="";
IGNORE_FILE="";
VERSION="1.0.0"

## Global colors
BLUE="\e[34m";
GREEN="\e[32m";
RED="\e[31m";
YELLOW="\e[33m"
RESET="\e[0m";

function header {
  echo -e "${BLUE}#####################
# 🔧 ${RESET}🆁🅴🅴🅽${BLUE} (script)  #
############# ${VERSION} #${RESET}";
}

function help {
  header;
  echo -e "-h - Show help
-d - Directory path for destiny of the backup
-s - File with directories to backup
-i - File with directories to be ignored in the backup
";
}

function log_level {
  # First parameter represnets the level for the log
  # Second parameter represents the message to log
  if [ $1 == "0" ]; # Info level 
  then
    echo -e "${GREEN} ✅ ${2}${RESET}"
  fi

  if [ $1 == "1" ]; # Warning level
  then
    echo -e "${YELLOW} ⚠️  ${2}${RESET}"
  fi

  if [ $1 == "2" ]; # Error level
  then
    echo -e "${RED} ❌ ${2}${RESET}"
  fi
}

function validate_dir {
  # Validates dir exists or creates it
  if [ -z $1 ];
  then
    log_level "2" "Missing required parameter for directory";
    help;
    exit;  
  fi
}

function validate_file {
  # Validates if global var of a file is not empty
  if [ -z $1 ];
  then
    log_level "2" "Missing required parameter";
    help;
    exit;
  fi

  # Validates if file is empty
  if ! [[ -s $1 ]];
  then
    log_level "2" "Not found or empty file ${1}";
    exit;
  fi
}

function main {

  start_time="$(date -u +%s)"

  # Validations
  validate_file $SOURCE_FILE;
  
  if ! [[ -z "${IGNORE_FILE}" ]];
  then
    validate_file $IGNORE_FILE;
  fi

  validate_dir $DEST;
  
  # Print input parameters
  # header;
  
  if ! [[ -z "${IGNORE_FILE}" ]];
  then
    echo -e "[Ignoring] => ${IGNORE_FILE}";  
  fi  
  echo -e "[Source] => $SOURCE_FILE"; 
  echo -e "[Destiny] => $DEST";
  echo -e " "; 

  # Validates dest directory 
  if [ ! -d "${DEST}" ];
  then
    mkdir -p "${DEST}";
    log_level "0" "... Destiny directory created";
  fi
  
  for i in $(cat $SOURCE_FILE ); do
    if [ -n $i ]; # If is not an empty line
    then
      if [ ! -d $i ]; # If it is not a directory
      then
        if [ -f "${i}" ]; # If its a file and exists
        then
          echo -n -e "\t${YELLOW} 🕑 Backing up file ${i}${RESET}" 
          rsync "${i}" "${DEST}"
          echo  -e "\r\t${GREEN} ✅ Done file ${i} ${RESET}          " 
        else
          log_level "1" "Directory or file ${i} not found"
        fi
      else
        echo -n -e "\t${YELLOW} 🕑 Backing up directory ${i}${RESET}" 
        rsync -a --exclude-from={"${IGNORE_FILE}",} "${i}"  "${DEST}"
        echo  -e "\r\t${GREEN} ✅ Done directory ${i} ${RESET}          " 
      fi
    fi
  done

  end_time="$(date -u +%s)"
  elapsed="$(($end_time-$start_time))"
  echo -e "\nBackup finished in $elapsed seconds."
  # tree "${DEST}";
}

while getopts ":hd:s:i:" option; do
  case $option in
    h) # Display help  
      help
      exit;;
    d) # Set destiny global var
      DEST="${OPTARG}";
      ;;
    s) # Set source global var
      SOURCE_FILE="${OPTARG}";
      ;;
    i) # Set ignore global var
      IGNORE_FILE="${OPTARG}";
      ;;
    \?) # Invalid option
      echo "ERROR: Invalid option";
      help;
      exit;;
  esac
done 

main;
