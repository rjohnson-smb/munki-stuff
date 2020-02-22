#!/bin/bash

# Creates printer preference file.
# 
# For each user, add ~/Library/Preferences/com.apple.print.custompresets.plist.

# Comment this to stop debug
debug=1

# File(s) to copy
pfiles="$(ls ./pfiles/*)"

# Find users:
userlist=$(dscl . list /Users | egrep -v '_|daemon|ladmin|nobody|root')

if [ $debug ]; then
	echo "Users on system:
${userlist}"
	echo
	echo "pfiles to install:
${pfiles}"
fi

for username in ${userlist}; do
	for pfile in ${pfiles}; do
		if [ $debug ]; then
			echo "Installing ${pfile}"
		fi
		
		pfilebase="$(basename /Users/${username}/Library/Preferences/${pfile})"
		userpfile="/Users/${username}/Library/Preferences/${pfilebase}"
		
		if [ -f ${userpfile} ]; then
			if [ ${debug} ]; then
				echo "File exists: ${userpfile}"
				echo "Aborting this user..."
			fi
		else
			if [ ${debug} ]; then
				echo "Copying file ${userpfile}"
			fi
			
			cp ${pfile} ${userpfile}
			
			# Set owner
			chown ${username} ${userpfile}
			
			# Verify owner
			fileowner=$(ls -l ${userpfile} | awk '{print $3}')
			
			if [ ${fileowner} != ${username} ]; then
				
				if [ ${debug} ]; then
					echo "Owner does not match. Aborting..."
					
					ls -l ${userpfile}
				fi
				
				rm ${userpfile}
				
				exit 1
			fi
			
			# Set binary mode
			plutil -convert binary1 ${userpfile}
			
			# Verify binary mode
			filemode=$(file ${userpfile} | grep -o "Apple binary property list")
			
			if [ "${filemode}" != "Apple binary property list" ]; then
				if [ ${debug} ]; then
					echo "File is not binary. Aborting..."
					
					file ${userpfile}
				fi
				
				rm ${userpfile}
				exit 1
			fi
		fi
	done
done