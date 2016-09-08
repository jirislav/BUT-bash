#!/bin/bash

helperFileName="$(dirname $0)/helper.sh"
source $helperFileName

if [ -z "$1" ]; then
	echo "No apid provided !"
	exit 2000
fi

APID="$1"

parseApidURL() {
	URL="$APID_URL"
	parseURL
	parseExamPart
}

parseExamPart() {
	examPart=$(cat "$html" | grep -B1 -A1000 zkouška | grep -B1000 -m 2 m_ppzc | hxnormalize -edxL)
	examLogoutLink=$(echo "$examPart" | hxselect -s "\n" "div.m_podnadpis" | grep "odhlásit" | awk 'BEGIN{FS="\""}{print $2}' | hxunent)
}

registerFirstExamWithFreeSlots() {
	local regLink=$(echo "$examPart" | hxselect -cs "\n" "div.m_podnadpis" | grep "přihlásit" | head -n 1 | awk 'BEGIN{FS="\""}{print $2}' | hxunent)

	if [ "$regLink" ]; then
		URL="https://www.vutbr.cz/studis/$regLink"

		echo "Našel jsem volné místo, registruji se ..."

		parseURL
		if [ $? -eq 0 ]; then
			echo "Registrace proběhla úspěšně :)"
			return 0
		else
			echo "Něco je špatně :/"
			return 1
		fi

	else
		echo -e "Nemohu se přihlásit na žádnou zkoušku z předmětu '$SUBJECT'\n podívejte se prosím 'ručně' na tuto URL: $APID_URL"
		return 1
	fi
}

#171639
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

#hxnormalize -edxL "$html" | hxselect -s '\n' "input[checked]" | egrep -v "disabled|radio" | awk 'BEGIN{ORS="&"; FS="name=\"|\""}{print $8"=on"}'
