#!/bin/bash

# Version of the script
VERSION="0.0.3"

## Global colors
BLUE="\e[34m";
GREEN="\e[32m";
RED="\e[31m";
YELLOW="\e[33m"
GRAY="\e[35m"
RESET="\e[0m";


# File with list of hostnames
SOURCE="";
# File of the action script
SCRIPT="";
# Mode of the execution
MODE="IdentityFile"
# Index of only server to affect
SERVER_INDEX=""
# Indexes of servers to exclude
EXCLUDE_INDEXES=()
# Extra variables
VARIABLE_EXTRA=""

function help {
  echo -e "Opciones:

  -s [ruta de config con hostnames de los servidores]
  -a [ruta de script a ejecutar en elos servidores remotamente]
* -v [variabes extras para ejecución del script]
* -i [índice del único servidor a afectar de la lista]
* -e [índices de servidores a excluir de la lista separador por ',' ó ';']
* -p [bandera para indicar si usará contraseña escrita en password.txt]

* Parámetros opcionales
  ";
}

function exit_error {
  echo -e "${RED} ${1} ${RESET}";
  exit 1;
}

function server_info {
    echo -e "${YELLOW}
🖥️  ($2) $1
----------------------------
    ${RESET}";
}

function excluded_server_info {
    echo -e "${GRAY}
⚠️  ($2) $1 was excluded
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
    echo -e "${GREEN}Usando el script: ${SCRIPT}${RESET}";
  else
    exit_error "⚙️  El script '${SCRIPT}' no existe";
  fi

  # Validamos los servidores a afectar
  if [[ -n $SERVER_INDEX ]]; then 
    # if index is especified
    rows=$(grep "Host " $SOURCE | awk -v i=$SERVER_INDEX  'NR==i{print $2}');
  else
    rows=$(grep "Host " $SOURCE | awk '{print $2}');
  fi


  # Save the current IFS value
  old_ifs="$IFS"
  # Set IFS to ';,'
  IFS=';,'
  # Read the string into an array
  read -ra allExcluded <<< "$EXCLUDE_INDEXES"
  # Restore the old IFS value
  IFS="$old_ifs"

  # for excluded in "${allExcluded[@]}"; do
  #   echo "Excluded $excluded"
  # done

  COUNTER=1
  for host in $rows; do
    if [[ $(echo ${allExcluded[@]} | fgrep -w $COUNTER) ]]
    then
      excluded_server_info $host $COUNTER;
    else
      server_info $host $COUNTER;

      # Use password strategy
      if [[ "$MODE" == "IdentityFile" ]]; then
        ssh $host "${VARIABLE_EXTRA}" 'bash -s' < $SCRIPT;
      else
        sshpass -f password.txt ssh $host "${VARIABLE_EXTRA}" 'bash -s' < $SCRIPT;
      fi
    fi

    COUNTER=$(( COUNTER + 1 ))
  done

}

###
# Options parser
####
header;

while getopts ":h :pa:s:i:e:v:" option; do
  case $option in
    a)
      SCRIPT=$OPTARG;
      ;;
    s)
      SOURCE=$OPTARG;
      ;;
    v)
      VARIABLE_EXTRA=$OPTARG;
      ;;
    i)
      SERVER_INDEX=$OPTARG;
      ;;
    e)
      EXCLUDE_INDEXES=$OPTARG;
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


