#!/bin/bash

# ===================================================
# FileSort - Downloads Folder Organizer
# Author: SpreadSheets
# Version: 1.0
# ===================================================


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

DOWNLOADS_FOLDER="${HOME}/Downloads"

LOGS_FOLDER="${DOWNLOADS_FOLDER}/.filesort_logs"
CURRENT_LOG="${LOGS_FOLDER}/$(date +%Y%m%d_%H%M%S).log"
LAST_LOG=$(ls -t "${LOGS_FOLDER}"/*.log 2>/dev/null | head -n 1)


mkdir -p "${LOGS_FOLDER}" 2>/dev/null

# ===================================================
# HELPER FUNCTIONS
# ===================================================


display_banner() {
    echo -e "${BOLD}${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║   ${GREEN}FileSort${BLUE} - Organize Your Downloads Folder by Extension   ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

log_message() {
    local type=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    case $type in
        "info")
            echo -e "${CYAN}[INFO]${RESET} ${timestamp} - ${message}"
            ;;
        "success")
            echo -e "${GREEN}[SUCCESS]${RESET} ${timestamp} - ${message}"
            ;;
        "warning")
            echo -e "${YELLOW}[WARNING]${RESET} ${timestamp} - ${message}"
            ;;
        "error")
            echo -e "${RED}[ERROR]${RESET} ${timestamp} - ${message}"
            ;;
        "action")
            echo -e "${PURPLE}[ACTION]${RESET} ${timestamp} - ${message}"
            ;;
        *)
            echo -e "${timestamp} - ${message}"
            ;;
    esac

    echo "${timestamp} - [${type}] ${message}" >> "${CURRENT_LOG}"
}

display_help() {
    echo -e "${BOLD}Usage:${RESET}"
    echo -e "  ${0} [OPTIONS]"
    echo
    echo -e "${BOLD}Options:${RESET}"
    echo -e "  ${GREEN}-h, --help${RESET}      Display this help message"
    echo -e "  ${GREEN}-u, --undo${RESET}      Undo the last sorting operation"
    echo -e "  ${GREEN}-d, --dir PATH${RESET}  Specify a different directory to sort (default: ~/Downloads)"
    echo -e "  ${GREEN}-l, --list${RESET}      List available undo operations"
    echo
    echo -e "${BOLD}Examples:${RESET}"
    echo -e "  ${0}                   # Sort the Downloads folder"
    echo -e "  ${0} --undo            # Undo the last sorting operation"
    echo -e "  ${0} --dir ~/Desktop   # Sort the Desktop folder"
}

list_undo_operations() {
    echo -e "${BOLD}${BLUE}Available Undo Operations:${RESET}"
    if [ -d "${LOGS_FOLDER}" ] && [ "$(ls -A ${LOGS_FOLDER} 2>/dev/null)" ]; then
        echo -e "${YELLOW}ID  |  Date Time          |  Files Sorted${RESET}"
        echo -e "${YELLOW}----+---------------------+-------------${RESET}"

        local count=1
        for log_file in $(ls -t "${LOGS_FOLDER}"/*.log 2>/dev/null); do
            local datetime=$(basename "${log_file}" | sed 's/\.log$//' | sed 's/_/ /' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\) \([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
            local files_count=$(grep -c "\[action\] Moving" "${log_file}")
            printf "${GREEN}%-4s${RESET}|  ${CYAN}%-19s${RESET}|  ${PURPLE}%-13s${RESET}\n" "$count" "$datetime" "$files_count files"
            count=$((count + 1))
        done
    else
        echo -e "${YELLOW}No Undo Operations Available${RESET}"
    fi
}

get_folder_name() {
    local ext=$1
    if [[ "${ext}" == "no_extension" ]]; then
        echo "NO EXTENSION Files"
    else
        echo "$(echo ${ext} | tr '[:lower:]' '[:upper:]') Files"
    fi
}

# ===================================================
# MAIN FUNCTIONS
# ===================================================

sort_files() {
    local total_files=0
    local total_sorted=0
    local skipped=0

    log_message "info" "Starting to sort files in ${DOWNLOADS_FOLDER}"

    if [ ! -d "${DOWNLOADS_FOLDER}" ]; then
        log_message "error" "Directory ${DOWNLOADS_FOLDER} does not exist!"
        exit 1
    fi

    total_files=$(find "${DOWNLOADS_FOLDER}" -maxdepth 1 -type f -not -path "*/\.*" | wc -l)
    log_message "info" "Found ${total_files} files to organize"

    find "${DOWNLOADS_FOLDER}" -maxdepth 1 -type f -not -path "*/\.*" | while read file; do
        filename=$(basename "${file}")

        if [[ -f "${file}.filesort_processing" ]]; then
            log_message "warning" "Skipping ${filename} - already being processed"
            skipped=$((skipped + 1))
            continue
        fi

        touch "${file}.filesort_processing"

        extension="${filename##*.}"
        if [[ "${filename}" == "${extension}" ]]; then
            extension="no_extension"
        fi
        extension=$(echo "${extension}" | tr '[:upper:]' '[:lower:]')
        folder_name=$(get_folder_name "${extension}")

        category_folder="${DOWNLOADS_FOLDER}/${folder_name}"
        mkdir -p "${category_folder}" 2>/dev/null

        target="${category_folder}/${filename}"
        if [[ -f "${target}" ]]; then
            local count=1
            local name="${filename%.*}"
            local ext="${filename##*.}"

            if [[ "${name}" == "${ext}" ]]; then # No extension or filename is the extension
                while [[ -f "${category_folder}/${name}_${count}" ]]; do
                    count=$((count + 1))
                done
                target="${category_folder}/${name}_${count}"
            else
                while [[ -f "${category_folder}/${name}_${count}.${ext}" ]]; do
                    count=$((count + 1))
                done
                target="${category_folder}/${name}_${count}.${ext}"
            fi
        fi

        log_message "action" "Moving ${filename} → ${folder_name}/"
        mv "${file}" "${target}" 2>/dev/null

        rm -f "${file}.filesort_processing" 2>/dev/null

        total_sorted=$((total_sorted + 1))

        percentage=$((total_sorted * 100 / total_files))
        progress_bar="["
        for ((i=0; i<percentage/5; i+=1)); do
            progress_bar="${progress_bar}█"
        done
        for ((i=percentage/5; i<20; i+=1)); do
            progress_bar="${progress_bar} "
        done
        progress_bar="${progress_bar}] ${percentage}%"
        echo -ne "${BLUE}Progress: ${progress_bar}${RESET}\r"
    done

    echo
    log_message "success" "Sorting Complete! ${total_sorted}/${total_files} files organized"

    find "${DOWNLOADS_FOLDER}" -name "*.filesort_processing" -delete 2>/dev/null

    echo
    echo -e "${BOLD}${BLUE}Created Categories:${RESET}"
    echo -e "${YELLOW}Category          |  Count${RESET}"
    echo -e "${YELLOW}-----------------+-------${RESET}"

    for category in "${DOWNLOADS_FOLDER}"/*" Files"/; do
        if [ -d "${category}" ]; then
            category_name=$(basename "${category}")
            file_count=$(find "${category}" -type f | wc -l)
            printf "${GREEN}%-17s${RESET}|  ${PURPLE}%5s${RESET}\n" "${category_name}" "${file_count}"
        fi
    done
}

undo_operation() {
    if [ -z "${LAST_LOG}" ] || [ ! -f "${LAST_LOG}" ]; then
        log_message "error" "No Previous Sorting Operation Found To Undo!"
        return 1
    fi

    log_message "info" "Undoing The Last Sorting Attempt"

    grep "\[action\] Moving" "${LAST_LOG}" | while read -r line; do
        source_file=$(echo "${line}" | sed -E 's/.*Moving (.*) → (.*)\/.*/\1/')
        dest_dir=$(echo "${line}" | sed -E 's/.*Moving (.*) → (.*)\/.*/\2/') # Corrected this sed, was missing the folder part

        source_path="${DOWNLOADS_FOLDER}/${dest_dir}/${source_file}"
        dest_path="${DOWNLOADS_FOLDER}/${source_file}"

        if [ ! -f "${source_path}" ]; then
            log_message "warning" "Unable Undo Move For ${source_file} - File Not Found!"
            continue
        fi

        if [ -f "${dest_path}" ]; then
            local filename="${source_file}"
            local count=1
            local name="${filename%.*}"
            local ext="${filename##*.}"

            if [[ "${name}" == "${ext}" ]]; then # No extension or filename is the extension
                while [[ -f "${DOWNLOADS_FOLDER}/${name}_restored_${count}" ]]; do
                    count=$((count + 1))
                done
                dest_path="${DOWNLOADS_FOLDER}/${name}_restored_${count}"
            else
                while [[ -f "${DOWNLOADS_FOLDER}/${name}_restored_${count}.${ext}" ]]; do
                    count=$((count + 1))
                done
                dest_path="${DOWNLOADS_FOLDER}/${name}_restored_${count}.${ext}"
            fi

            log_message "warning" "File Conflict Resolved: ${source_file} → $(basename "${dest_path}")"
        fi

        log_message "action" "Restoring ${source_file} to Downloads folder"
        mv "${source_path}" "${dest_path}" 2>/dev/null
    done

    find "${DOWNLOADS_FOLDER}" -type d -name "* Files" -empty -delete 2>/dev/null

    mv "${LAST_LOG}" "${LAST_LOG}.undone" 2>/dev/null

    log_message "success" "Undo Operation Completed Successfully!"
}

# ===================================================
# SCRIPT EXECUTION
# ===================================================

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help)
            display_banner
            display_help
            exit 0
            ;;
        -u|--undo)
            display_banner
            undo_operation
            exit 0
            ;;
        -l|--list)
            display_banner
            list_undo_operations
            exit 0
            ;;
        -d|--dir)
            DOWNLOADS_FOLDER="$2"
            shift # Consume value
            ;;
        *)
            log_message "error" "Unknown Option: $1"
            display_help
            exit 1
            ;;
    esac
    shift # Consume key
done

display_banner
sort_files
echo

log_message "info" "To Undo This Operation, Run: $0 --undo"
