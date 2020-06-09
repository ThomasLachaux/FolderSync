# Log functions
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

# Folder functions
checkFolders() {
  [[ -d $folderA ]] || error "Le dossier A n'existe pas"
  [[ -d $folderB ]] || error "Le dossier B n'existe pas"
}

# Liste le dossier récursivement et supprime le dossier racine
listFolder() {
  folderName=$1
  find $folderName | cut -d / -f 2- | sed '1d'
}

# Journal functions
listFolderExplicit() {
  folderName=$1
  # Supprime les lignes commençant par total
  find $folderName -exec ls -ld --time-style='+%Y-%m-%d-%H-%M-%S' {} + | sed '1d' | sed "s/$folderName\///"
}

getFileMetadatas() {
  ls -ld --time-style='+%Y-%m-%d-%H-%M-%S' $1 | awk '{print $1,$3,$4,$5,$6}'
}

getFileOwner() {
  ls -ld $1 | awk '{print $3,$4}' | sed 's/\ /\:/'
}

# Help with https://bit.ly/3dqAJcN
# Prints the permissions in octal
getFilePermissions() {
  ls -ld $1 | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf("%0o ",k);print $1}' | cut -c -3
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

getJournalFileName() {
  file=$1
  cat $journalPath | awk '{print $7}' | grep -Fx "$file"
}

# Retourne à quelle ligne du journal le fichier se situe
getJournalFileLineLocation() {
  file=$1
  cat $journalPath | awk '{print $7}' | grep -Fnx "$file" | cut -d : -f 1
}

getJournalFileMetadatas() {
  file=$1
  line=$(getJournalFileLineLocation $file)
  cat $journalPath | awk '{print $1,$3,$4,$5,$6}' | sed -n "${line}p"
}

# $1 source
# $2 dest
checkAndCopy() {
  if [[ -f $1 ]]; then
    cp -p $1 $2
  else
    # Verifie si le proprio/groupe a changé
    if [[ $(getFileOwner $1) != $(getFileOwner $2) ]]; then
      # Seul le root peut lancer chown, verification si on est root
      if [[ $UID == 0 ]]; then
        chown $(getFileOwner $1) $2
      else
        echo "La possession du dossier $1 est différente du dossier $2 et seul le root peut le modifier"
      fi
    fi

    if [[ $(getFilePermissions $1) != $(getFilePermissions $2) ]]; then
      chmod $(getFilePermissions $1) $2 2> /dev/null || echo "Vous n'avez pas les droits pour modifier $2"
    fi
  fi
}

# Path functions
# Removes ./
popCurrentDir() {
  folder=$1
  echo $folder | sed 's/^\.\///'
}

# Get three first metadatas from a ls output
compareFoldersMeta123() {
  folder=$1
  ls -ld $folder | awk '{print ($1,$2,$3)}'
}
