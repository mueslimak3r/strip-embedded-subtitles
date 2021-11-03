#!/bin/bash

# This script strips embedded subtitles from video files
# The script can leave a backup of the old files if specified, and can restore or remove the backups

RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[1;93m'
PURPLE='\033[1;35m'
BLACK='\033[0;30m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

file_pattern="*.mp4$|*.flv$|*.mkv$"

INPUT_DIR=$1

# values: NORMAL TESTRUN RESTORE CLEAN LISTBACKUPS
OPERATION_MODE="NORMAL"

# set by --DESTROY_OLD
IS_DESTRUCTIVE=0

list_old() {
    BACKUP_NAME="$1"
    NEW_FILE_NAME=${BACKUP_NAME::-4}
    echo -e "${CYAN}Found backup of ${PURPLE}$NEW_FILE_NAME${NC}"
}

restore_old() {
    BACKUP_NAME="$1"
    NEW_FILE_NAME=${BACKUP_NAME::-4}
    rm "$NEW_FILE_NAME"
    mv "$BACKUP_NAME" "$NEW_FILE_NAME"
    echo -e "${CYAN}Restored backup of ${PURPLE}$NEW_FILE_NAME${NC}"
}

remove_old() {
    BACKUP_NAME="$1"
    ORIGINAL_FILE_NAME=${BACKUP_NAME::-4}
    rm "$BACKUP_NAME"
    echo -e "${CYAN}Removed backup ${PURPLE}$ORIGINAL_FILE_NAME${CYAN}_old${NC}"
}

test_run() {
    INPUT_FILE="$1"
    INPUT_FILE_BACKUP="$1_old"

    if [ "$1" == "" ] ; then
        echo "invalid file"
    else
        if [[ -e "$INPUT_FILE" ]] ; then
            if [[ $(ffprobe "$INPUT_FILE" 2>&1 | grep -E Subtitle) == "" ]] ; then
                echo -e "$INPUT_FILE ${PURPLE}doesnt contain subtitles${NC}"
            else
                echo -e "$INPUT_FILE ${YELLOW}contains subtitles${NC}"
                echo -e "Would ${RED}Remove${NC} or ${CYAN}keep${NC} backup file: ${PURPLE}$INPUT_FILE_BACKUP${NC} in non-test mode"
            fi
        else
            echo "$INPUT_FILE does not exist"
        fi
    fi
}

strip_subs() {
    INPUT_FILE="$1"
    INPUT_FILE_BACKUP="$1_old"

    if [ "$1" == "" ] ; then
        echo "invalid file"
    else
        if [[ -e "$INPUT_FILE" ]] ; then
            if [[ $(ffprobe "$INPUT_FILE" 2>&1 | grep -E Subtitle) == "" ]] ; then
                echo -e "$INPUT_FILE ${PURPLE}doesnt contain subtitles${NC}"
            else
                echo -e "$INPUT_FILE ${YELLOW}contains subtitles${NC}"
                if [[ -e "$INPUT_FILE_BACKUP" ]] ; then
                    echo -e "${RED}A backup file for this video already exists. Skipping to avoid corrupting an original file${NC}"
                else
                    mv "$INPUT_FILE" "$INPUT_FILE_BACKUP"
                    #< /dev/null ffmpeg -i "$INPUT_FILE_BACKUP" -map 0 -map -0:s -c copy "$INPUT_FILE" -hide_banner -loglevel panic 2>&1
                    #exit
                    if [[ $(< /dev/null ffmpeg -i "$INPUT_FILE_BACKUP" -map 0 -map -0:s -c copy "$INPUT_FILE" -hide_banner -loglevel panic -y 2>&1) != "" ]] ; then
                        echo -e "${RED}something went wrong with ffmpeg${NC}"
                        restore_old "$INPUT_FILE_BACKUP"
                    else
                        echo -e "${GREEN}finished processing $INPUT_FILE${NC}"
                        if [[ ${IS_DESTRUCTIVE} == 1 ]] ; then
                            echo -e "${RED}Removed backup file: ${PURPLE}$INPUT_FILE_BACKUP${NC}"
                            rm "$INPUT_FILE_BACKUP"
                        else
                            echo -e "${CYAN}Kept backup file: ${PURPLE}$INPUT_FILE_BACKUP${NC}"
                        fi
                    fi
                fi
            fi
        else
            echo "$INPUT_FILE does not exist"
        fi
    fi
}

#export RED
#export GREEN
#export YELLOW
#export PURPLE
#export BLACK
#export CYAN
#export NC

#export IS_DESTRUCTIVE

#export -f strip_subs
#export -f remove_old
#export -f restore_old
#export -f list_old
#export -f test_run

if [[ "$INPUT_DIR" == "/" || "$INPUT_DIR" == "/mnt" || "$INPUT_DIR" == "/mnt/" || "$INPUT_DIR" == "/boot" || "$INPUT_DIR" == "/boot/" ]] ; then
    echo -e "${RED}Stopping script from running on [${PURPLE}$INPUT_DIR]${RED} for user safety${NC}\n"
    exit
fi

if [[ $(ffmpeg 2>&1 | grep version) == "" ]]; then
    echo -e "${RED}ffmpeg either isn't installed or isn't reachable${NC}\n"
    exit
fi


if [ "$INPUT_DIR" == "" ] || [ "$2" == "" ] || [[ "$2" != "--TEST" && "$2" != "--KEEP_OLD=YES" && "$2" != "--KEEP_OLD=NO" && "$2" != "--RESTORE_BACKUPS" && "$2" != "--REMOVE_BACKUPS" && "$2" != "--LIST_BACKUPS" ]]; then
    echo -e "\nusage: strip_subs.sh /path/to/media/folder --TEST ${YELLOW}or${NC} --KEEP_OLD=YES/NO ${YELLOW}or${NC} --LIST/RESTORE/REMOVE_BACKUPS"
    echo -e "\n${PURPLE}--KEEP_OLD=YES/NO${NC} controls deleting the backup files containing subtitles"
    echo -e "If you keep the backup files it will ${RED}double your hard drive usage${NC}"
    echo -e "\n${PURPLE}--LIST/RESTORE/REMOVE_BACKUPS${NC} can list, restore, or remove the old files containing subtitles\n"
    echo -e "\n${PURPLE}--TEST${NC} runs the script without affecting your files\n"
    exit
else
    if [[ "$2" == "--KEEP_OLD=NO" ]] ; then
        IS_DESTRUCTIVE=1
        echo -e "${PURPLE}Stripping subtitles from videos inside ${RED}$INPUT_DIR${NC}"
        echo -e "After stripping subtitles the backups of the old files will be ${RED}destroyed${NC}\n\n"
    elif [[ "$2" == "--KEEP_OLD=YES" ]] ; then
        IS_DESTRUCTIVE=0
        echo -e "${PURPLE}Stripping subtitles from videos inside ${RED}$INPUT_DIR${NC}"
        echo -e "After stripping subtitles the backups of the old files will be ${CYAN}kept${NC}\n\n"
    elif [[ "$2" == "--TEST" ]] ; then
        OPERATION_MODE="TESTRUN"
        echo -e "${PURPLE}Stripping subtitles from videos inside ${RED}$INPUT_DIR${NC}"
        echo -e "After stripping subtitles the backups of the old files may be ${CYAN}kept${NC} or ${RED}destroyed${NC}\n"
        echo -e "${GREEN}TEST RUN${NC}\n\n"
    elif [[ "$2" == "--LIST_BACKUPS" ]] ; then
        OPERATION_MODE="LISTBACKUPS"
        file_pattern="*_old$"
        echo -e "${PURPLE}Listing backups of videos inside ${RED}$INPUT_DIR${NC}\n\n"
    elif [[ "$2" == "--RESTORE_BACKUPS" ]] ; then
        OPERATION_MODE="RESTORE"
        file_pattern="*_old$"
        echo -e "${PURPLE}Restoring backups of videos inside ${RED}$INPUT_DIR${NC}\n\n"
    elif [[ "$2" == "--REMOVE_BACKUPS" ]] ; then
        OPERATION_MODE="CLEAN"
        file_pattern="*_old$"
        echo -e "${PURPLE}Removing backups of videos inside ${RED}$INPUT_DIR${NC}\n\n"
    fi
fi

files=$(find "$INPUT_DIR" -type f 2>/dev/null | egrep "$file_pattern")

if [[ "$files" == "" || $(echo -e "$files" | wc -l)  -eq 0 ]]; then
   echo -e "${RED}No matching files found in $INPUT_DIR${NC}"
else
    echo "found $(echo "$files" | wc -l) files"
    while IFS= read -r line
    do
        if [[ "$OPERATION_MODE" == "NORMAL" ]] ; then
            strip_subs "$line"
        elif [[ "$OPERATION_MODE" == "TESTRUN" ]] ; then
            test_run "$line"
        elif [[ "$OPERATION_MODE" == "LISTBACKUPS" ]] ; then
            list_old "$line"
        elif [[ "$OPERATION_MODE" == "RESTORE" ]] ; then
            restore_old "$line"
        elif [[ "$OPERATION_MODE" == "CLEAN" ]] ; then
            remove_old "$line"
        fi
    done < <(printf '%s\n' "$files")
fi