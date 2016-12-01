#!/bin/bash

logs=logs
logfile="$logs-${2/*\//}-$3"
mailto="mail@jkozlovsky.cz"
printSyntax() {
	echo
	echo -e "Syntax: ./loopThrough.sh 5 final-exam-reRegister.sh \"160569\""
	echo 
	echo -e "        - first argument specifies number of seconds to wait between"
	echo -e "          the calls of second argument until at least one of these"
	echo -e "          calls succeeds"
	echo -e "          - it can be formatted as 'MIN-MAX' where MIN & MAX defines"
	echo -e "            interval in which should be an random generated foreach"
	echo -e "            script call"
	echo
	echo -e "        - second argument specifies bash script to call"
	echo
	echo -e "        - third argument specifies arguments to pass to that script"

	exit 1
}

if [ -z "$1" ]; then
	echo
	echo "Please provide number of seconds to wait between program executions until success"
	printSyntax
fi

if [ -z "$2" ]; then
	echo
	echo "Please provide the name of script to run until success with provided interval of repetition"
	printSyntax
fi

if [ ! -f "$2" ]; then
	echo
	echo "File '$2' doesn't exists! Please provide a valid bash script!"
	printSyntax
fi

if [ -z "$3" ]; then
	echo
	echo "Please provide an argument for '$2' !"
	printSyntax
fi

# Sanate the interval
isRange=$(echo "$1" | egrep "^[0-9]+-[0-9]+$")
if [ "$isRange" ]; then
	min=$(echo "$1" | awk -F- '{print $1}')
	max=$(echo "$1" | awk -F- '{print $2}')

	if [ ! $max ] || [ ! $min ]; then
		echo "Range given is wrongly formatted"
		printSyntax
	fi
#elif ! [[ "$1" =~ '^[0-9]+$' ]]; then # Checks it really is a number ..
#	echo "Please provide interval in seconds !"
#	printSyntax
fi

echo >> "$logfile"
date >> "$logfile"
/bin/bash "$2" "$3" | tee -a "$logfile"

while [ ! ${PIPESTATUS[0]} -eq 0 ]; do

	if [ "$isRange" ]; then
		interval=$(( $min + $RANDOM % $(( $max - $min )) ))

		echo "Choosing interval $interval secs"

		sleep $interval
	else
		sleep $1
	fi

	echo >> "$logfile"
	date >> "$logfile"
	/bin/bash "$2" "$3" | tee -a "$logfile"

done

echo
echo "Finally, the program '$2' succeded !! :)"

export SUBJECT="The job in BUT-bash is done!"
export TEXT_MESSAGE="Looks like job '${logfile/$logs-/}' was successfully completed!\n Seeya!"
envsubst < .mail.template.txt | sendmail $mailto

