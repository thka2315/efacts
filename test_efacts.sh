#!/bin/bash

. efacts.sh

humanuser=$(system_users)
echo "Username: ${humanuser}"
for ffdir in $(firefox_profile_directories "${humanuser}"); do
    echo "Firefox profile directory: ${ffdir}"
    nssdbtype "$ffdir"
done
for tbdir in $(thunderbird_profile_directories "${humanuser}"); do
    echo "Thunderbird profile directory: ${tbdir}"
    nssdbtype "$ffdir"
done

