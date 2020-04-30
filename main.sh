#!/bin/bash -e

# Doit pouvoir être overridden par des variables d'environnement du même nom
FOLDER_A="./syncA"
FOLDER_B="./syncB"
JOURNAL_PATH="./journal.txt"

log() {
  echo -e "\e[90m[$(date +"%Y-%m-%d %H:%M:%S")]\e[39m $@"
}

warn() {
  log "\e[33mWARN:\e[39m $@"
}

info() {
  log "\e[32mINFO:\e[39m $@"
}

debug() {
  log "\e[34mDEBUG:\e[39m $@"
}

error() {
  log "\e[31mERROR:\e[39m $@"
  exit 1
}

checkBaseFolders() {
  [[ -d $FOLDER_A ]] || error "Le dossier A n'existe pas"
  [[ -d $FOLDER_B ]] || error "Le dossier B n'existe pas"
}

getJournal() {
  # Crée le journal s'il n'existe pas
  if [[ ! -f $JOURNAL_PATH ]]; then
    touch $JOURNAL_PATH
  fi
}

checkBaseFolders
getJournal

a_content=($(ls $FOLDER_A))
b_content=($(ls $FOLDER_B))

lengthA=${#a_content[@]}
lengthB=${#b_content[@]}

debug "Dossier A: $lengthA fichier(s)"
debug "Dossier B: $lengthB fichier(s)"

indexA=0
indexB=0

itemA=${a_content[$indexA]}
itemB=${b_content[$indexB]}

absoluteItemA="$FOLDER_A/$itemA/"
absoluteItemB="$FOLDER_B/$itemB"

debug "Compare $itemA et $itemB"

if [[ $itemA == $itemB ]]; then
  if [[ -d $absoluteItemA && -f $absoluteItemB ]]; then
    error "$absoluteItemA est un dossier et $absoluteItemB est un fichier"

  elif [[ -f $absoluteItemA && -d $absoluteItemB ]]; then
    error "$absoluteItemA est un fichier et $absoluteItemB est un dossier"

  else
    debug "$absoluteItemB"
  fi
else
  debug "$absoluteItemA différent de $absoluteItemB"
fi