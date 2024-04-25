#!/bin/bash

SCRIPT_VERSION="0.0.1"
FIELDS=("Título" "Artista" "Álbum" "Número de pista" "Fecha" "Letras")
COVER_FILE_NAME="Cover.png"
COVERS_DIR_NAME="covers"
MusicLibrary="/media/evesan/TRANSCEND/1-iTunesLibrary/Music";
SOURCE=""; # Source directory to find files
INFO_FILE="info.csv";

ARTIST_NAME=""
ALBUM_NAME=""
ALBUM_YEAR=""
ALBUM_COVER=""

## Global colors
BLUE="\e[34m";
GREEN="\e[32m";
RED="\e[31m";
YELLOW="\e[33m"
PURPLE="\e[35m"
GRAY="\e[37m"
RESET="\e[0m";

## FORMATS
MP3="mp3"
M4A="mp4a"
FLAC="flac"
WAV="pcm_s"


function header {
  echo -e "${YELLOW}
░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░ █▀▄▀█ █░░ █ █▄▄          ░
░ █░▀░█ █▄▄ █ █▄█ (v${SCRIPT_VERSION}) ░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░
${RESET}"
}

function help {
  echo -e "  Flags:
    ${YELLOW}* -d ${GRAY}[specifies directory to use]${RESET}
    ${YELLOW}  -i ${GRAY}[shows info of a directory]${RESET}
    ${YELLOW}  -e ${GRAY}[extract image covers]${RESET}
    ${YELLOW}  -c ${GRAY}[convert, can convert to mp3 or wav]${RESET}
    ${YELLOW}  -f ${GRAY}[fill metadata of all files of all tags in a directory]${RESET}
    ${YELLOW}  -g ${GRAY}[generate ${INFO_FILE} file]${RESET}
    ${YELLOW}  -h ${GRAY}[shows help]${RESET}

  ${YELLOW}* (required)${RESET}
"
}

function generate_csv {
  echo -e "${GREEN}Proive information for the album.${RESET}";
  echo -n -e "${GREEN}Artist${RESET}: ";
  read ARTIST_I;
  echo -n -e "${GREEN}Album${RESET}: ";
  read ALBUM_I;
  echo -n -e "${GREEN}Year${RESET}: ";
  read YEAR_I;
  echo -n -e "${GREEN}Cover${RESET} ${GRAY}(default=${COVER_FILE_NAME})${RESET}: ";
  read COVER_I;

  if [[ -z "${COVER_I}" ]]; then
    COVER_I="${COVER_FILE_NAME}"
  fi

  echo "Artist,Album,Year,Cover" > "${INFO_FILE}";
  echo "${ARTIST_I},${ALBUM_I},${YEAR_I},${COVER_I}" >> "${INFO_FILE}";
}

function parse_csv {
  if [[ -f  "${INFO_FILE}" ]]; then
    old_ifs="${IFS}";
    while IFS="," read -r artist album year cover
    do
      echo "Artist: ${artist}"
      echo "Album: ${album}"
      echo "Year: ${year}"
      echo "Cover: ${cover}"
      ARTIST_NAME="${artist}"
      ALBUM_NAME="${album}"
      ALBUM_YEAR="${year}"
      ALBUM_COVER="${cover}"
      echo ""
    done < <(tail -n +2 "${INFO_FILE}")
    IFS="${old_ifs}";
  else
    echo -e "${YELLOW}No ${INFO_FILE} detected ${RESET}"
  fi
}


##
## Function that retirves a field from a metadata string with all the information
##
function get_field_from {
  field="${1}";
  metadata="${2}";

  value=$(echo "${metadata}" | grep  -E "${field}" | awk 'NR==1' | sed 's/  //g' | sed "s/${field}//g" | sed -e 's/^[[:space:]]*//');
  echo "${value}";
}

##
## This function prints all array FIELDS from a file in a spcecific tag
##
function print_tag_n {
  file="${1}";
  n="${2}";

  allMeta=$(kid3-cli "${file}" -c "get all ${n}");
  for field in "${FIELDS[@]}"; do
    value=$(get_field_from "${field}" "${allMeta}");
    echo -e "\t ${PURPLE}[${n}]${field}${RESET}: ${value}";
  done
}

function download_cover {
  url="${1}";
  is_link=$(echo "${url}" | grep "http")
  if ! [[ -z "${is_link}" ]]; then
    curl "${url}" -o "${COVER_FILE_NAME}";
    ALBUM_COVER="${COVER_FILE_NAME}";
  fi
}

##
## This function complete all the tags based in TAG-1 ot TAG-2
##
function complete_tags {
  cover_file=""
  # Test if cover file exists
  if ! [[ -z "${ALBUM_COVER}" ]]; then
    download_cover "${ALBUM_COVER}";
    cover_file="${ALBUM_COVER}";
  else
    cover_file="${COVER_FILE_NAME}";
  fi

  if ! [[ -f "${cover_file}" ]]; then
    echo -e "${RED}*Cover not found at $(pwd)/${cover_file} ${RESET}";
    exit 1;
  fi

  # Get content of this directory and set metadada
  for file in *; do 
    if [[ "${file}" == "${COVER_FILE_NAME}" ]]; then
      # Do not do anything with cover file
      continue
    fi
    if [[ "${file}" == "${INFO_FILE}" ]]; then
      # Do not do anything with cover file
      continue
    fi
    
    echo -e "\n### ${GREEN}${file} ### ${RESET}\n";

    tag1Metadata=$(kid3-cli "${file}" -c "get all 1");
    tag2Metadata=$(kid3-cli "${file}" -c "get all 2");
    tag3Metadata=$(kid3-cli "${file}" -c "get all 3");

    # iterate over fields and set field_value
    for field in "${FIELDS[@]}"; do
      field_value="";
      # Get value from global variable
      case "${field}" in
        "Artista")
          field_value="${ARTIST_NAME}";
        ;;
        "Álbum")
          field_value="${ALBUM_NAME}";
        ;;
        "Fecha")
          field_value="${ALBUM_YEAR}";
        ;;
      esac

      # Get value from other tags
      if [[ -z "${field_value}" ]]; then
        tag1Value=$(get_field_from "${field}" "${tag1Metadata}");
        tag2Value=$(get_field_from "${field}" "${tag2Metadata}");
        tag3Value=$(get_field_from "${field}" "${tag3Metadata}");
      
        if ! [[ -z "${tag3Value}" ]]; then
          field_value="${tag3Value}";
        else
          if ! [[ -z "${tag2Value}" ]]; then
            field_value="${tag2Value}";
          else
            if ! [[ -z "${tag1Value}" ]]; then
              field_value="${tag1Value}";
            else
              echo -e "\t ${RED}Field not found ${field}${RESET}";
            fi
          fi
        fi
      fi

      echo -e "\t${YELLOW}Setting ${field} to ${field_value}${RESET}";

      kid3-cli "${file}" -c "set \"${field}\" \"${field_value}\" 1" 2>&1;
      kid3-cli "${file}" -c "set \"${field}\" \"${field_value}\" 2" 2>&1;
      kid3-cli "${file}" -c "set \"${field}\" \"${field_value}\" 3" 2>&1;
    done

    # Add cover file
    echo -e "\t${YELLOW}Setting ${cover} to ${cover_file}${RESET}";
    kid3-cli "${file}" -c "set picture:'./${cover_file}' 'Album cover'";

    print_tag_n "${file}" "1"
    print_tag_n "${file}" "2"
    print_tag_n "${file}" "3"

  done
}

function convert_to_mp3 {
  dst_dir="mp3";
  mkdir -p "${dst_dir}";

  for file in *; do
    if [[ "${file}" == "${COVER_FILE_NAME}" ]]; then
      # Do not do anything with cover file
      continue
    fi
    echo -e "\n### ${GREEN}${file} ### ${RESET}\n";

    # Obtain all info
    file_info=$(ffprobe "${file}" 2>&1)

    ## MP4 to MP3
    is_mp4a=$(echo "${file_info}" | grep "Stream" | grep "Audio" | grep "${M4A}")
    if ! [[ -z "${is_mp4a}" ]]; then
      echo -e "${BLUE} MP4A detected ... converting ${RESET}";
      ## Convert it
      ffmpeg -i "${file}" -c:v copy -c:a libmp3lame -q:a 4 ${dst_dir}/"${file%.*}.mp3"
    fi

    ## WAV to MP3
    is_wav=$(echo "${file_info}" | grep "Stream" | grep "Audio" | grep "${WAV}")
     if ! [[ -z "${is_wav}" ]]; then
      echo -e "${BLUE} WAV detected ... converting ${RESET}";
      ## Convert it
      ffmpeg -i "${file}" -vn -ar 44100 -ac 2 -b:a 320k ${dst_dir}/"${file%.*}.mp3";
    fi

    ## FLAC to MP3
    is_flac=$(echo "${file_info}" | grep "Stream" | grep "Audio" | grep "${FLAC}")
    if ! [[ -z "${is_flac}" ]]; then
      echo -e "${BLUE} Flac detected ... converting ${RESET}";
      ## Convert it
      ffmpeg -i "${file}" -ab 320k -map_metadata 0 -id3v2_version 3 ${dst_dir}/"${file%.*}.mp3";
    fi
  done
}

function convert_to_wav {
  dst_dir="wav"
  mkdir -p "${dst_dir}";
  for file in *; do
    if [[ "${file}" == "${COVER_FILE_NAME}" ]]; then
      # Do not do anything with cover file
      continue
    fi
    
    echo -e "\n### ${GREEN}${file} ### ${RESET}\n";
    # Obtain all info
    file_info=$(ffprobe "${file}" 2>&1)

    ## FLAC to WAV
    is_flac=$(echo "${file_info}" | grep "Stream" | grep "Audio" | grep "${FLAC}")
    if ! [[ -z "${is_flac}" ]]; then
      echo -e "${BLUE} Flac detected ... converting ${RESET}";
      ## Convert it
      ffmpeg -i "${file}" -c:a pcm_s24le -map_metadata 0 ${dst_dir}/"${file%.*}.wav";
    fi
  done
}


function show_tags_info {
  echo -e "${GREEN}\nAvailable information: ${RESET}";
  for file in *; do
    if [[ "${file}" == "${COVERS_DIR_NAME}" ]]; then 
      continue
    fi
    if [[ "${file}" == "${COVER_FILE_NAME}" ]]; then 
      continue
    fi
    echo -e "\n\t${GREEN}${file}${RESET}";
    print_tag_n "${file}" "1"
    print_tag_n "${file}" "2"
    print_tag_n "${file}" "3"
  done
}

function extract_cover {
  for file in *; do 
    
    if [[ -f "${file}" ]]; then
      covers_dir="covers";
      file_name=$( echo "${covers_dir}/${file%.*}.png" | sed "s/'//g"  );
      mkdir -p "${covers_dir}";
      kid3-cli "${file}" -c "get picture:'${file_name}'" 
    fi
  done

}

function set_source {
  if [[ -z "${SOURCE}" ]]; then
    source=$(tree -d -f -i | fzf);
    SOURCE="${MusicLibrary}/${source}";
  fi
  cd "${SOURCE}";
  echo -e "${GREEN}Using directory ${SOURCE}${RESET}";
}

header;

while getopts ":h :i :e :g :fd:c:" option; do
  case $option in
    d)
      SOURCE="${OPTARG}";
      ;;
    i)
      set_source;
      show_tags_info;
      ;;
    e)
      set_source;
      extract_cover;
      ;;
    g)
      set_source;
      generate_csv;
      ;;
    c)
      set_source;
      case "${OPTARG}" in
        "${MP3}")
            convert_to_mp3;
          ;;
        "wav")
            convert_to_wav;
            echo "${OPTARG}";
          ;;
      esac
      ;;
    f)
      set_source;
      parse_csv;
      complete_tags;
      ;;
    h)
      help;
      exit;;
    \?)
      help;
      exit;;
  esac
done