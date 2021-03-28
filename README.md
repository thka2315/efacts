# efacts

This is a bash script with functions to help other scripts determine facts on a system.


## system_users
Parameters: None

Tries to guess the human users on the system, using a scoring system.

 - Get all users wih uid 1000 and above
 - Does the home directory exists?
 - Does the home directory have dotfiles?
 - Count active processes
 - Is the user logged in?
 - Check lastlog for user logins

The user with highest score gets returned by the function

## user_exists
Parameters: username

Returns True or False is the username exists

## user_home_dir
Parameters: username

Returns the users home directory

## firefox_profile_directories
Parameters: username

Returns all Firefox profiles base directories

## thunderbird_profile_directories
Parameters: username

Returns all Thunderbird profiles base directories
