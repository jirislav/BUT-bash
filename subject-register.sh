#!/bin/bash

helperFileName="$(dirname $0)/helper.sh"
source $helperFileName

if [ -z "$1" ]; then
	echo "No apid provided !"
	exit 2000
fi

APID="$1"

URL="https://www.vutbr.cz/studis/student.phtml?sn=individualni_plan_fekt"
parseURL

hiddenData=$(hxnormalize -edxL "$html" | hxselect -s '\n' "input[type=hidden]" | egrep -v "name=\"type|name=\"hact" |  awk 'BEGIN{ORS="&"; FS="\""}{print $2"="$6}' | sed 's:sn=individualni_plan_fekt&chmat_js=0&::')
oldInput="$(hxnormalize -edxL "$html" | hxselect -s '\n' "input[checked]" | egrep -v "disabled|radio" | awk -F "name=\"" '{print $2}' | cut -d\" -f1 | awk 'BEGIN{ORS="&"}{print $1"=on"}')"
newInput="$(hxnormalize -edxL "$html" | hxselect -s '\n' "input#pr$APID" | awk -F "name=\"" '{print $2}' | cut -d\" -f1)"

data="${hiddenData}${oldInput}${newInput}=on"

echo "$data"
parseURLWithDataPOST

if [ $? -eq 0 ] ; then
	echo "Registrace předmětu $APID byla úspěšná!"
	exit 0
else
	exit 1
fi
