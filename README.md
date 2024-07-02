# User Management Script README

## Overview

This script automates the process of creating Linux user accounts and managing their group memberships. It ensures secure storage of user passwords and logs all activities.

## Script Details

- **Script Name**: `create_users.sh`
- **Script Language**: Bash
- **Purpose**: Automate user creation, password management, and group assignments.

## Directory and File Setup

The script checks for and creates necessary directories and files:

1. **Secure Directory and File**:
   - **Directory**: `/var/secure`
   - **File**: `user_passwords.txt`
   - **Permissions**: Directory `700`, File `600`
   
2. **Log Directory and File**:
   - **Directory**: `/var/log`
   - **File**: `user_management.log`
   - **Permissions**: Directory `755`, File `644`

## Usage

### Run the Script

To run the script, use the following command:

```sh
sudo ./create_users.sh <input_file>
```

### Input File Format

The input file should contain lines with the following format:

```
username;group1,group2,...
```

- **username**: The name of the user to be created.
- **group1,group2,...**: A comma-separated list of groups to which the user should be added.

### Example Input File

```
john;admin,developers
jane;users
```

### Script Execution

1. **Create Directories and Files**: Ensures the secure and log directories and files exist.
2. **Check Input File**: Validates the presence of the input file and reads users and groups from it.
3. **Run with Root Privileges**: Ensures the script is run with root or sudo privileges.
4. **User Creation**: For each user:
   - Checks if the user already exists.
   - Generates a random password.
   - Adds the user and sets their password.
   - Creates the user's home directory.
   - Logs user creation details.
5. **Group Management**: For each group:
   - Checks if the group exists.
   - Adds the user to the group, creating the group if it doesn't exist.
   - Logs group assignment details.

## Functions

### `create_directory_and_file()`

Ensures the specified directory and file exist, with correct ownership and permissions.

### `generate_password()`

Generates a random password of specified length.

### `create_user()`

Creates a user account, sets the password, and creates the home directory.

### `user_groups()`

Manages group assignments for the user, creating groups if necessary.

## Logging

The script logs all activities and errors to `/var/log/user_management.log` with timestamps.

## Security

- Passwords are securely stored in `/var/secure/user_passwords.txt`.
- Permissions ensure that only the script owner can read or modify sensitive files.

## Conclusion

This script provides a secure and efficient way to manage user accounts and group memberships on a Linux system. Ensure you run it with the necessary privileges and provide a correctly formatted input file for optimal results.