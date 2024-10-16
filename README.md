# erase-install-policy
Run erase-install via MDM policy

This script was designed for and tested in Jamf but should be adapted to any MDM workflow.

The first option that should be passed is either "reinstall" or "erase" depending on what you what the erase-install script to do. The default is "reinstall" if nothing is passed.
The second option is the version of macOS that should be installed (i.e. "14"). There is an option to input "sameos" in this field.
