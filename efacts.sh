#!/bin/bash

# efacts - Extended facts for Linux
# Copyright 2021 Thomas Karlsson
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

user_exists() {
    local user="$1"

    if getent passwd "$user" >/dev/null; then return 1; fi

    return 0
}

count_users_processes() {
    local processuser="$1"
    if user_exists "$processuser"; then
        ps --no-headers -u "$processuser" |wc -l
        return 0
    fi

    echo 0
    return 1
}

dotobjects_in_homedirectory() {
    local username="$1"

    userhomedir=$(user_home_dir "$username")
    if [ ! -d "$userhomedir" ]; then echo 0; return 0; fi
    if [ ! -r "$userhomedir" ]; then echo 0; return 0; fi
    find "$userhomedir" -maxdepth 1 -name ".*" | wc -l

    return 0
}

user_loggedin() {
    local username="$1"

    if which loginctl >/dev/null; then
        awk "/^[0-9]+ ${username}/ { print \$1 }" < <(loginctl list-users) | wc -l
        return 0
    else
        echo 0
        return 1
    fi
}

lastlog_user() {
    local username="$1"

    last -s "30 days ago" | awk "BEGIN { counter=0 } /${username}/ { if (\$1 == \"${username}\") { counter++ } } END { print counter }"
    return 0
}

system_users() {
    # Get the normal system user in a single user system,
    # using a scoring system
    declare humanusers
    declare -A users
    while read -r potentialuser; do
        users["$potentialuser"]=1
        userhomedir=$(user_home_dir "$potentialuser")
        if [ -d "$userhomedir" ]; then ((users["$potentialuser"]++)); fi
        if [ "$(count_users_processes "$potentialuser")" -gt 0 ]; then ((users["$potentialuser"]++)); fi
        if [ "$(dotobjects_in_homedirectory "$potentialuser")" -gt 0 ]; then ((users["$potentialuser"]++)); fi
        if [ "$(user_loggedin "$potentialuser")" -gt 0 ]; then ((users["$potentialuser"]++)); ((users["$potentialuser"]++)); fi
        if [ "$(lastlog_user "$potentialuser")" -gt 0 ]; then ((users["$potentialuser"]++)); fi
    done < <(getent passwd | awk -F: '{ if ($3 >= 1000) { print $1 }}')
    highestscore=0
    for oneuser in "${!users[@]}"; do
        if [ "${users[$oneuser]}" -eq $highestscore ]; then
            humanusers+=("$oneuser")
        elif [ "${users[$oneuser]}" -gt $highestscore ]; then
            highestscore=${users[$oneuser]}
            humanusers=("$oneuser")
        fi
    done

    echo "${humanusers[@]}"
    return 0
}

user_home_dir() {
    local username="$1"

    passwdline=$(getent passwd "$username")
    if [ -z "$passwdline" ]; then
        echo ""
        return
    fi

    echo "$passwdline" | awk -F: '{ print $6 }'
    return 0
}

firefox_profile_directories() {
    local username="$1"

    home_dir=$(user_home_dir "$username")
    if [ ! -d "${home_dir}/.mozilla" ]; then echo ""; return; fi
    if [ ! -d "${home_dir}/.mozilla/firefox" ]; then echo ""; return; fi

    if [ ! -f "${home_dir}/.mozilla/firefox/profiles.ini" ]; then echo ""; return; fi

    declare -a directories
    while read -r mozilladir; do
        # directories=("${directories[@]}" "${home_dir}/.mozilla/firefox/${mozilladir}")
        directories+=("${home_dir}/.mozilla/firefox/${mozilladir}")
    done < <(awk -F= '/^Path=/ { print $2 }' "${home_dir}/.mozilla/firefox/profiles.ini")

    echo "${directories[@]}"
    return 0
}

thunderbird_profile_directories() {
    local username="$1"

    home_dir=$(user_home_dir "$username")
    if [ ! -d "${home_dir}/.thunderbird" ]; then echo ""; return; fi
    if [ ! -f "${home_dir}/.thunderbird/profiles.ini" ]; then echo ""; return; fi

    declare -a directories
    while read -r mozilladir; do
        directories=("${directories[@]}" "${home_dir}/.thunderbird/${mozilladir}")
    done < <(awk -F= '/^Path=/ { print $2 }' "${home_dir}/.thunderbird/profiles.ini")

    echo "${directories[@]}" 
    return 0
}
