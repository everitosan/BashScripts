#!/bin/bash

## Global variables
SYSTEMDDIR="/etc/systemd/system"
NAME="" # Name of the service
DESC="" # Description of the service
WD="$(pwd)" # Working directory
APP="$(pwd)/" # App entry point
USER="$(whoami)" # User to run

## Global colors
BLUE="\e[34m"
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"


BASE_FILE='[Unit]
\nDescription=$DESC
\nAfter=network.target
\n
\n[Service]
\nType=simple
\nRestart=always
\nUser=$USER
\nWorkingDirectory=$WD
\nExecStart=$APP
\n
\n[Install]
\nWantedBy=multi-user.target
'


function die {
  echo -e "💣 ${RED} ${1} ${RESET}";
  exit 1;
}

echo -n -e "⌨️${GREEN}  Provide the name of the service${RESET}: ";
read NAME;
if [[ -z $NAME ]]; then
  die "Name ${NAME} is not valid";
else
  NAME=${NAME// /-}
fi

echo -n -e "⌨️${GREEN}  Provide the description of the service${RESET}: ";
read DESC;
if [[ -z $DESC ]]; then
  die "Description ${DESC} is not valid";
fi

echo -n -e "⌨️${GREEN}  Provide the user that will run the app${RESET} [default:${USER}]: ";
read USERI;
if ! [[ -z $USERI ]]; then
  id $USERI 2>&1 > /dev/null;
  if [ $? == "0" ]; then
    USER=$USERI;
  else
    die "User ${USERI} not found";
  fi
fi

echo -n -e "⌨️${GREEN}  Provide the working directory${RESET} [default:${WD}]: ";
read WDI;
if ! [[ -z $WDI ]]; then
  # Validate if working dir exists does not exist
  if ! [[ -d $WDI ]]; then
    die "Directory ${WD} does not exist."
  else
    WD=$WDI;
  fi
fi

echo -n -e "⌨️${GREEN}  Provide the app entry point ${RESET}(Relative path will use working dir): ";
read APPI;
if ! [[ -z $APPI ]]; then
  # Fix name
  startingPath=${APPI:0:1};
  if [[ $startingPath != "/" ]]; then
    APPI="${WD}/${APPI}"
  fi

  # Validate if file does not exist
  if ! [[ -s $APPI ]]; then
    die "File ${APPI} does not exist."
  else
    APP=$APPI;
  fi
fi

echo -e "⚙️ ${YELLOW} Generating service for '${NAME}' ... ${RESET}";

# Use sed with pipe delimiter to avoid collisions with path slash
outFile=$(echo -e $BASE_FILE | 
  sed "s|\$WD|$WD|g" | # replace working direcotry
  sed "s|\$USER|$USER|g" | # replace user
  sed "s|\$DESC|$DESC|g" | # replace description
  sed "s|\$APP|$APP|g"); # replace application to execute

echo -e "${BLUE}${outFile}${RESET}";

echo -n -e "${GREEN}⌨️  Should try to install it under ${SYSTEMDDIR}${RESET} [default:y]: ";
read -n 1 INSTALLI;

if [ -z $INSTALLI ] || [ $INSTALLI == "y" ] ; then
  echo -e "⚙️ ${YELLOW} Installing service ... ${RESET}";
  echo -e "${outFile}"  > "${SYSTEMDDIR}/${NAME}.service";
fi

echo -e "\n⚙️ ${YELLOW} Remeber to enable the service to start after reboot using ${GREEN} systemctl enable ${NAME}.service ${RESET}"
