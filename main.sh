#!/bin/bash -e

source ./functions.sh
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

checkFolders() {
  [[ -d $folderA ]] || error "Le dossier A n'existe pas"
  [[ -d $folderB ]] || error "Le dossier B n'existe pas"
}


getJournal() {
  # Crée le journal s'il n'existe pas et synchronise A --> B
  if [[ ! -f $journalPath ]]; then
    rm -rf $folderB
    cp -pr $folderA $folderB
    log "Copie $folderA --> $folderB"
    listFolderExplicit $folderA > $journalPath
    echo "Dossier synchronisé"
    exit 0
  fi
}

listJournal() {
  cat $journalPath | awk '{print $7}'
}

checkFolders
getJournal

sync() { 

  for file in $(listFolder $folderA); do

    folderA=$1
    folderB=$2

    metadataA=$(ls $folderA/$file)
    # Regarde si le fichier existe dans la destination
    if [[ -e $folderB/$file ]]; then

      # Si c'est un fichier dans la source et que c'est un dossier dans la destination
      if [[ -f $folderA/$file && -d $folderB/$file ]]; then
        warn "Conflit ! $folderA/$file est un fichier et $folderB/$file est un dossier"
        wantToContinue

      # Si c'est un dossier dans la source et que c'est un fichier dans la destination
      elif [[ -d $folderA/$file && -f $folderB/$file ]]; then
        warn "Conflit ! $folderA/$file est un dossier et $folderB/$file est un fichier"
        wantToContinue
      
      # Sinon, récupère le fichier dans le journal
      elif [[ $(getJournalFileName ${file}) ]]; then
        journalDate=$(getJournalFileMetadatas ${file})

        if [[ $(getFileMetadatas $folderA/$file) != $(getFileMetadatas $folderB/$file) ]]; then

          unset REPLY
          # Si c'est un fichier: comparer la date et les permission + proprio + groupe pour vérifier si un conflit existe
          # Si c'est un dossier: comprare juste les permission + proprio + groupe

          # Si c'est un fichier
          if [[ -f $folderA/$file && $journalDate != $(getFileMetadatas $folderA/$file) && $journalDate != $(getFileMetadatas $folderB/$file) ]]; then 
            while [[ $REPLY != 1 || $REPLY != 2 ]] ; do
              warn "Conflit sur le fichier $file !"
              echo "1) Garder $folderA/$file"
              echo "2) Garder $folderB/$file"
              echo "3) Afficher les différences"
              read
              if [[ $REPLY == 1 ]]; then
                checkAndCopy $folderA/$file $folderB/$file
                break
              elif [[ $REPLY == 2 ]]; then
                checkAndCopy $folderB/$file $folderA/$file
                break
              elif [[ $REPLY == 3 ]]; then
                if [[ -f $folderA/$file ]]; then 
                  diff -y --suppress-common-lines $folderA/$file $folderB/$file || true
                fi
              fi
            done

          # Si c'est un dossier, compare le seulement les droits, le proprio et le groupe 
          elif [[ -d $folderA/$file && $journalDate != $(getFolderMetadatas $folderA/$file) && $journalDate != $(getFolderMetadatas $folderB/$file) ]]; then
            
            while [[ $REPLY != 1 || $REPLY != 2 ]] ; do
              warn "Conflit sur le dossier $file !"
              echo "1) Garder $folderA/$file [$(getFolderMetadatas $folderA/$file)]"
              echo "2) Garder $folderB/$file [$(getFolderMetadatas $folderB/$file)]"
              read

              if [[ $REPLY == 1 ]]; then
                checkAndCopy $folderA/$file $folderB/$file
                break
              elif [[ $REPLY == 2 ]]; then
                checkAndCopy $folderB/$file $folderA/$file
                break
              fi
            done

          else
            if [[ $journalDate !=  $(getFileMetadatas $folderA/$file) ]]; then
              checkAndCopy $folderA/$file $folderB/$file
              
            elif [[ $journalDate !=  $(getFileMetadatas $folderB/$file) ]]; then
              checkAndCopy $folderB/$file $folderA/$file
            fi
          fi
        fi

      else
        error "Le fichier journal est incomplet ou incorrect. Veuillez le supprimer"
        exit 1
      fi

    else
      # grep -Fx checks all the line and ignore special character which can be in the ${file}
      if [[ $(getJournalFileName ${file}) ]]; then
        # Le fichier existe dans le journal
        rm -r $folderA/$file
        log "Remove $folderA/$file"

      else
        # check si le fichier est un dossier ou ono
        [[ -d $folderA/$file ]] && cp -pr $folderA/$file $folderB || cp -p $folderA/$file $folderB/$file
        log "Copie $folderA/$file --> $folderB/$file"
      fi
    fi
  done

  # Ajout dans le journal
  listFolderExplicit $folderA > $journalPath
}
sync $folderA $folderB

info "Synchronisation terminée"