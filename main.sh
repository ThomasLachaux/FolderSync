#!/bin/bash -e

# Doit pouvoir être overridden par des variables d'environnement du même nom
if [[ -d $1 ]]; then
	folderA=$1
else 
	echo "Le premier argument n'est pas un dossier."
	exit 1
fi
if [[ -d $2 ]]; then
	folderB=$2
else
	echo "Le deuxième argument n'est pas un dossier."
	exit 1
fi
journalPath="./journal.txt"

# Supprime les ./ si il existe, très utile quand on fera de la saisie
folderA=$(echo $folderA | sed 's/^\.\///')
folderB=$(echo $folderB | sed 's/^\.\///')

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

checkFolders() {
  [[ -d $folderA ]] || error "Le dossier A n'existe pas"
  [[ -d $folderB ]] || error "Le dossier B n'existe pas"
}

# Liste le dossier récursivement et supprime le dossier racine
listFolder() {
  folderName=$1
  find $folderName | cut -d / -f 2- | sed '1d'
}

listFolderExplicit() {
  folderName=$1
  # Supprime les lignes commençant par total
  find $folderName -exec ls -ld --time-style='+%Y-%m-%d %H:%m' {} + | sed '1d' | sed "s/$folderName\///"
}


getJournal() {
  # Crée le journal s'il n'existe pas et synchronise A --> B
  if [[ ! -f $journalPath ]]; then
    rm -rf $folderB
    cp -r $folderA $folderB
    listFolderExplicit $folderA > $journalPath
    echo "Dossier synchronisé"
    exit 0
  fi
}

listJournal() {
  cat $journalPath | awk '{print $8}'
}

checkFolders
getJournal


for file in $(listFolder $folderA); do
  metadataA=$(ls $folderA/$file)

  # Check if file or directory exists
  if [[ ! -e $folderB/$file ]]; then
    echo "Fichier manquant ! : $file"
    # grep -Fx checks all the line and ignore special character which can be in the ${file}
    if [[ $(listJournal | grep -Fx "${file}") ]]; then
      # Le fichier existe dans le journal
      rm -rv $folderA/$file

    else
      echo "Le fichier n'existe pas dans le journal"
      # check si le fichier est un dossier ou ono
      [[ -d $folderA/$file ]] && cp -vr --parents $folderA/$file $folderB/$file || cp $folderA/$file $folderB/$file

    fi
  fi
done
listFolderExplicit $folderA > $journalPath
