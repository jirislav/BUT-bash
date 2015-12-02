#!/bin/bash

helperFileName="$(dirname $0)/helper.sh"
source $helperFileName

if [ -z "$1" ]; then
	echo "No apid provided !"
	exit 2000
fi

# Set first argument to the apid of the subject to reRegister into
URL="https://www.vutbr.cz/studis/student.phtml?sn=terminy_zk&apid=$1"
APID_URL="$URL"
parseURL

parseExamPart() {
	examPart=$(cat "$html" | grep -B1 -A1000 zkouška | grep -B1000 -m 2 m_ppzc | hxnormalize -edxL)
}

parseExamPart

SUBJECT=$(echo $examPart | hxselect -cs "\n" "div.m_nadpis span.hlavni")

if [ ! "$examPart" ]; then
	echo "No exams published yet .."
	exit 2001
fi

examLogoutLink=$(echo "$examPart" | hxselect -s "\n" "div.m_podnadpis" | grep "odhlásit" | awk 'BEGIN{FS="\""}{print $2}' | hxunent)

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

# Now we have three possibilities:
# Not logged in anywhere -> log into the first exam available ..
# Logged in somewhere -> end with success if already logged in to the first exam available
# Logged in somewhere -> determine if there are any free slots in preceding exams

if [ ! "$examLogoutLink" ]; then
	# 1st scenario
	registerFirstExamWithFreeSlots
	exit $?
else
	registeredExamNumber=$(echo $examPart | hxselect -s "\n" "div.m_podnadpis" | grep -n odhlásit | awk -F: '{print $1}')

	if [ "$registeredExamNumber" -eq 1 ]; then
		# 2nd scenario
		echo "Již máte zaregistrovaný nejbližší možný termín zkoušky z '$SUBJECT' :)"
	else
		# 3rd scenario ..

		examsInfos=$(echo $examPart | hxselect -s "\n" "div.m_tinfo")
		examsCount=$(echo "$examsInfos" | wc -l)

		# Iterate over the exam infos .. :)
		for (( i=1; i < $registeredExamNumber; ++i )); do

			currLine=$(echo "$examsInfos" | sed -n ${i}p)

			isWithoutSlots=$(echo $currLine | grep m_nespl_pod)

			if [ ! "$isWithoutSlots" ]; then
				# We have found better exam slot !! :D
				# Logout from the current registered slot & register this one !
				URL="https://www.vutbr.cz/studis/$examLogoutLink"
				parseURL

				parseExamPart

				registerFirstExamWithFreeSlots
				exit $?

			elif [ $i -eq $(( $registeredExamNumber - 1 )) ]; then
				echo "Na dřívějších termínech ze zkoušky z '$SUBJECT' stále není volné místo :/"
				exit 1
			fi

		done
	fi
fi


exit 0
