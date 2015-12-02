#!/bin/bash

printSyntax() {
	echo
	echo -e "Syntax: ./loopThrough.sh 5 final-exam-reRegister.sh \"160569\""
	echo 
	echo -e "        - first argument specifies number of seconds to wait between"
	echo -e "          the calls of second argument until at least one of these"
	echo -e "          calls succeeds"
	echo
	echo -e "        - second argument specifies bash script to call"
	echo
	echo -e "        - third argument specifies arguments to pass to that script"

}

if [ -z "$1" ]; then
	echo
	echo "Please provide number of seconds to wait between program executions until success"
	printSyntax
	exit 1
fi

if [ -z "$2" ]; then
	echo
	echo "Please provide the name of script to run until success with provided interval of repetition"
	printSyntax
	exit 1
fi

if [ ! -f "$2" ]; then
	echo
	echo "File '$2' doesn't exists! Please provide a valid bash script!"
	printSyntax
	exit 1
fi

if [ -z "$3" ]; then
	echo
	echo "Please provide an argument for '$2' !"
	printSyntax
	exit 1
fi

/bin/bash "$2" "$3"
while [ $? -eq 1 ]; do

	sleep $1
	/bin/bash "$2" "$3"

done

echo
echo "Finally, the program '$2' succeded !! :)"

