#!/bin/bash

helperFileName="$(dirname $0)/helper.sh"
source $helperFileName

if [ -z "$1" ]; then
	echo "No apid provided !"
	exit 2000
fi

# Set first argument to the apid of the subject to reRegister into
URL="https://www.vutbr.cz/studis/student.phtml?sn=terminy_zk&apid=$1"
parseURL

