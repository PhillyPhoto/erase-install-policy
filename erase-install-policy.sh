#!/bin/zsh

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
echoFunc "Installing the base erase-install script"
jamf policy -trigger eraseinstallbase

if [[ -e /Library/Management/erase-install/erase-install.sh ]]
then
    eiVer=$(cat /Library/Management/erase-install/erase-install.sh | grep -a "version=\"" -m1 | sed 's/^.........//' | sed 's/.$//')
    echoFunc "erase-install.sh found (version: '$eiVer'), continuing"
else
    echoFunc "erase-install.sh NOT found, exiting!"
    exitFunc 1
fi

# Variables passed by the policy
runType="$4"
macOSFVer=$5

echoFunc "Requested run type (if any):          '$runType'"
echoFunc "Current macOS Major version:          '$(sw_vers -productVersion | cut -d. -f1)'"
echoFunc "Requested macOS Major version:        '$(echo "$macOSFVer" | cut -d. -f1)'"

if [[ "$macOSFVer" == "" ]]
then
    echoFunc "ERROR: macOS version was blank, exiting!"
    exitFunc 2
elif [[ $(echo "$macOSFVer" | cut -d. -f1) -lt $(sw_vers -productVersion | cut -d. -f1) ]]
then
    echoFunc "ERROR: current macOS version is greater than the requested version, exiting!"
    exitFunc 3
fi

case $runType in
"erase")
    echoFunc "Erasing and installing macOS version: '$macOSFVer'"
    runTypeVar="--erase"
    ;;
"reinstall" | *)
    echoFunc "Reinstalling/upgrading macOS version: '$macOSFVer'"
    runTypeVar="--reinstall"
    ;;
esac

echoFunc "Running command:                      '/Library/Management/erase-install/erase-install.sh $runTypeVar --os=$macOSFVer --min-drive-space=40 --current-user --check-power --dialog-on-download --no-fs'"

/Library/Management/erase-install/erase-install.sh $runTypeVar --os=$macOSFVer --min-drive-space=40 --current-user --check-power --dialog-on-download --no-fs

exitFunc $?
