#!/bin/zsh

# This policy is meant to be run via a policy in Jamf but can be adapted for any MDM or even to run locally
# Variable 4 is the "reinstall" or "erase" flag and if left blank will use "reinstall"
# Variable 5 is the version of macOS to install (i.e. 14)

# Date and Time function for the log file
fDateTime () { echo $(date +"%a %b %d %T"); }

# Title for begining of line in log file
Title="EraseInstallPolicy:"

# Header string function
fHeader () { echo $(fDateTime) $(hostname) $Title; }

echoFunc () {
    echo $(fHeader) "$1"
    echo $(fHeader) "$1" >> /var/log/EraseInstallPolicy.log
}

exitFunc () {
    echoFunc "Exit code: '$1'"
    echoFunc "======================== Erase-Install via Policy Script Complete ========================"
    exit $1
}

echoFunc "======================== Starting Erase-Install via Policy Script ========================"

echoFunc "Run erase-install via policy"
echoFunc "Created by PhillyPhoto 28Sep23"

runType="$4"
macOSFVer="$5"
macOSInstVer="--sameos"
macOSPrdVer="$(/usr/bin/sw_vers -productVersion | awk -F '.' '{print $1}')"
macOSBldVer="$(/usr/bin/sw_vers -buildVersion | cut -c1-2)"
legacy=$(if [[ $macOSBldVer -ge 21 ]]; then echo "false"; else echo "true"; fi)

echoFunc "Installing erase-install"
jamf policy -trigger eraseinstallbase

if [[ -e /Library/Management/erase-install/erase-install.sh ]]
then
    eiVer=$(cat /Library/Management/erase-install/erase-install.sh | grep -a "version=\"" -m1 | sed 's/^.........//' | sed 's/.$//')
    echoFunc "erase-install.sh found (version: '$eiVer'), continuing"
else
    echoFunc "ERROR: erase-install.sh NOT found, exiting!"
    exitFunc 1
fi

if $legacy
then
    echoFunc "Legacy macOS detected, installing Swift Dialog 2.2.1"
    jamf policy -trigger swiftdialog221
fi

if [[ -e /usr/local/bin/dialog ]]
then
    echoFunc "SwiftDialog Version: '$(/usr/local/bin/dialog --version)'"
else
    echoFunc "ERROR: SwiftDialog NOT Found, exiting!"
    exitFunc 2
fi

echoFunc "Requested run type (if any):          '$runType'"
echoFunc "Current macOS Major version:          '$(sw_vers -productVersion | cut -d. -f1)'"
echoFunc "Requested macOS Major version:        '$(echo "$macOSFVer" | cut -d. -f1)'"

if [[ "$macOSFVer" == "" ]]
then
    echoFunc "Warning: macOS version was blank, setting to '$macOSPrdVer'!"
    macOSInstVer="--os=$macOSPrdVer"
elif [[ $(echo "$macOSFVer" | cut -d. -f1) -lt $(sw_vers -productVersion | cut -d. -f1) ]]
then
    echoFunc "ERROR: current macOS version is greater than the requested version, exiting!"
    exitFunc 3
elif [[ "$macOSFVer" == "sameos" ]]
then
    macOSInstVer="--sameos"
else
    macOSInstVer="--os=$macOSFVer"
fi

case $runType in
"erase")
    echoFunc "Erasing and installing macOS version: '$macOSFVer'"
    runTypeVar="--erase --confirm"
    ;;
"reinstall" | *)
    echoFunc "Reinstalling/upgrading macOS version: '$macOSFVer'"
    runTypeVar="--reinstall"
    ;;
esac

echoFunc "Setting runtime flag file"
runtimeFile="/var/log/erase-install/$(echo $(date +"%Y %b %d %H%M%S")).txt"
if [[ ! -d "/var/log/erase-install/" ]]
then
    mkdir "/var/log/erase-install/"
fi
echo "Command: '/Library/Management/erase-install/erase-install.sh $runTypeVar $macOSInstVer --min-drive-space=40 --check-power --power-wait-limit 300 --no-fs --rebootdelay 150 --no-timeout'" >> "$runtimeFile"

echoFunc "Running command:                      '/Library/Management/erase-install/erase-install.sh $runTypeVar $macOSInstVer --min-drive-space=40 --check-power --power-wait-limit 300 --no-fs --rebootdelay 150 --no-timeout'"
/Library/Management/erase-install/erase-install.sh $runTypeVar $macOSInstVer --min-drive-space=40 --rebootdelay 150 --check-power --power-wait-limit 300 --no-fs --no-timeout

exitFunc $?
