#!/bin/bash

# Version of the script
VERSION="0.0.1"

## Global colors
BLUE="\e[34m";
GREEN="\e[32m";
RED="\e[31m";
YELLOW="\e[33m"
RESET="\e[0m";


# File with list of hostnames
SOURCE="";
# File of the action script
SCRIPT="";
# Mode of the execution
MODE="IdentityFile"

function help {
  echo -e "Opciones:
  -s [ruta de config con hostnames de los servidores]
  -a [ruta de script a ejecutar en elos servidores remotamente]
  -p [bandera para indicar si usará contraseña escrita en password.txt]
  ";
}

function exit_error {
  echo -e "${RED} ${1} ${RESET}";
  exit 1;
}

function server_info {
    echo -e "${YELLOW}
🖥️  $1
----------------------------
    ${RESET}";
}

function header {
  echo -e "${YELLOW}

█─▄▄▄─█▄─▄▄▀█▄─▄█
█─███▀██─▄─▄██─██
▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▀  (${VERSION})
${RESET}
Ejecución remota de scripts
  ";
}

function main {
  # Si no indica el source, se va a pedir por prompt
  if [ "$SOURCE" == "" ]; then 
    read -p "Ingrese el config: " SOURCE;
  fi

  # Valida que el archivo exista
  if test -e "$SOURCE"; then
    echo -e "${GREEN}Usando el config: ${SOURCE}${RESET}";
  else
    exit_error "📄 El archivo config '${SOURCE}' no existe";
  fi

  # Si no indica el script, se va a pedir por prompt
  if [ "$SCRIPT" == "" ]; then 
    read -p "Ingrese el script: " SCRIPT;
  fi

   # Valida que el archivo exista
  if test -e "$SCRIPT"; then
    echo -e "${GREEN}Usando el script: ${SOURCE}${RESET}";
  else
    exit_error "⚙️  El script '${SOURCE}' no existe";
  fi


  for host in $(grep "Host " $SOURCE | awk '{print $2}'); do
    server_info $host;

    if [[ "$MODE" == "IdentityFile" ]]; then
      ssh $host 'bash -s arg' < $SCRIPT;
    else
      sshpass -f password.txt ssh $host 'bash -s arg' < $SCRIPT;
    fi
  done

}

###
# Options parser
####
header;

while getopts ":h :pa:s:" option; do
  case $option in
    a)
      SCRIPT=$OPTARG;
      ;;
    s)
      SOURCE=$OPTARG;
      ;;
    p)
      MODE="password";
      ;;
    h)
      help;
      exit;;
    \?)
      help;
      exit;;
  esac
done

###
# Main trigger
####
main;


