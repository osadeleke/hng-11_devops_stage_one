#!/bin/bash

SECURE_DIR='/var/secure'
SECURE_FILE="$SECURE_DIR/user_passwords.txt"
LOG_DIR='/var/log'
LOG_FILE="$LOG_DIR/user_management.log"
PASSWORD_LENGTH=8


# check for secure and log directory and file and create if it does not exists
create_directory_and_file() {
    local directory=$1
    local file=$2
    local owner=$3
    local dir_permissions=$4
    local file_permissions=$5

    # check if directory exists and create if it does not.
    if [ ! -d "$directory" ]; then
        mkdir -p "$directory"
    fi

    # checks if file exists and creates if it does not.
    if [ ! -f "$file" ]; then
        touch "$file"
    fi

    # sets ownership and permissions for directory and file respectively
    chown "$owner:$owner" "$directory" "$file"
    chmod "$dir_permissions" "$directory"
    chmod "$file_permissions" "$file"
}
create_directory_and_file "$LOG_DIR" "$LOG_FILE" "${SUDO_USER:-$(whoami)}" 755 644
create_directory_and_file "$SECURE_DIR" "$SECURE_FILE" "${SUDO_USER:-$(whoami)}" 700 600


# check for file path if provided
if [ $# -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Usage: $0 <input_file>" | tee -a $LOG_FILE
    exit 1
fi

# check if the file exists
input_file=$1
if [ ! -f "$input_file" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: File '$input_file' not found." | tee -a $LOG_FILE
    exit 1
fi

# checks if the script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - This script must be run as root or with sudo." | tee -a $LOG_FILE
    echo -e "Usage:\nsudo ./<name of script.sh> <file.txt>"
    exit 1
fi

# Generates a random password
generate_password() {
    tr -dc '[:alnum:]' < /dev/urandom | head -c "$PASSWORD_LENGTH"
    echo
}

# Function to create a user and their home directory
create_user() {
    local username=$1

    # check if user already exists
    if id "$username" &>/dev/null; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - User '$username' already exists." | tee -a $LOG_FILE
        return 1
    fi

    # generate password for user and logs in secure file
    local password=$(generate_password)
    echo "$username,$password" >> $SECURE_FILE

    # adds user. returns error if fail
    useradd -m -s /bin/bash "$username"
    if [ $? -ne 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Failed to add user '$username'." | tee -a $LOG_FILE
        return 1
    fi

    # sets user password. return error if fails.
    echo "$username:$password" | chpasswd
    if [ $? -ne 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Failed to set password for user '$username'." | tee -a $LOG_FILE
        return 1
    fi

    # creates user home directory and checks for fail
    local user_dir="/home/$username"
    mkdir -p "$user_dir"
    if [ $? -ne 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Failed to create home directory for user '$username'." | tee -a $LOG_FILE
        return 1
    fi

    # sets permissions and ownership and check for fail
    chown "$username:$username" "$user_dir"
    if [ $? -ne 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Failed to set ownership for home directory of user '$username'." | tee -a $LOG_FILE
        return 1
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') - User '$username' successfully created and home directory set up." | tee -a $LOG_FILE
}

# checking and creating user groups
user_groups() {
    local username=$1
    local groups=$2

    # iterates through groups if more than one
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        # checks if the group exists.
        if grep -q "^$group:" /etc/group; then
            # check if the user is part of the group. add if not.
            if id -nG "$username" | grep -qw "$group"; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - User '$username' is already in Group '$group'" | tee -a $LOG_FILE
            else
                usermod -aG "$group" "$username"
                if [ $? -ne 0 ]; then
                    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Failed to add user '$username' to group '$group'." tee -a $LOG_FILE
                else
                    echo "$(date '+%Y-%m-%d %H:%M:%S') - User '$username' added to $group" | tee -a $LOG_FILE
                fi
            fi
        # if the group does not exist, create the group and add user
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Group '$group' does not exist. creating group" | tee -a $LOG_FILE
            groupadd "$group"
            if [ $? -ne 0 ]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Failed to create Group '$group'." | tee -a $LOG_FILE
            else
                echo "$(date '+%Y-%m-%d %H:%M:%S') - '$group' successfully created." | tee -a $LOG_FILE
            fi
            usermod -aG "$group" "$username"
            if [ $? -ne 0 ]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Failed to add user '$username' to group '$group'." tee -a $LOG_FILE
            else
                echo "$(date '+%Y-%m-%d %H:%M:%S') - User '$username' added to newly created $group" | tee -a $LOG_FILE
            fi
        fi
    done
}

# === SCRIPT STARTS HERE ===
# read each line from the file
# get each user per line
while IFS=';' read -r user groups || [[ -n "$user" ]]; do
    user=$(echo "$user" | sed 's/ //g')
    groups=$(echo "$groups" | sed 's/ //g')
    create_user $user
    user_groups $user $groups

    # read all groups of a particular user
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(echo "$group" | xargs)
    done
# reads the input file containing users and groups
done < "$input_file"

echo "Completed"