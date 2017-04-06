#!/bin/bash

helperFileName="$(dirname $0)/helper.sh"
source $helperFileName

ERRORS=()
if [ -z "$APID" ]; then
	ERRORS+=("No apid provided !")
fi

if [ -z "$TID" ]; then
	ERRORS+=("No TID provided !")
fi

if test ${#ERRORS[@]} -ne 0; then
	for ERROR in "${ERRORS[@]}"; do
		echo "$ERROR" >&2
	done
	exit 150
fi

# Set first argument to the apid of the subject to reRegister into
APID_URL="https://www.vutbr.cz/studis/student.phtml?sn=terminy_zk&apid=$APID"

parseApidURL() {
	URL="$APID_URL"
	parseURL
	parseExamPart
	# echo "$examPart"
}

parseExamPart() {
	# We have to filter out the divs with "zkoušk" in it because of possible different types of exams than final exam
	# parent div defined as "m_ppzc" used to be one line above the match of "zkoušk", but we don't know where it ends,
	# so exclude all another m_ppzc ..

	possible_exam_parts=$(cat "$html" | hxnormalize -edxL | hxselect -s "\n" "div.page div.m_ppzc" | grep -B6 -A1000 zkoušk )

	# Ignore this (was neccessary only for registering the first exam)
	# 
	#if [ "`echo "$possible_exam_parts" | grep m_ppzc | wc -l`" -gt 1 ]; then
	#	# More than 1 type of registrations so cut it to the first one .. TODO resolve this possible bug of wanting to register to all the exams :)
	#	examPart=$(echo "$possible_exam_parts" | grep -B1000 -m 2 m_ppzc | hxnormalize -edxL )
	#else
	#	examPart="$possible_exam_parts"
	#fi
	
	examPart="$possible_exam_parts"
		
	examLogoutLink=$(echo "$examPart" | hxselect -s "\n" "div.m_podnadpis" | grep "odhlásit" | awk 'BEGIN{FS="\""}{print $2}' | hxunent)

	TID_EXISTS=`echo "$examPart" | grep -o "$TID"`

	if test -z "$TID_EXISTS"; then
		echo "TID=$TID not found for APID=$APID !" >&2
		echo "Please check '$APID_URL' and gimme the right TID" >&2
		exit 2
	fi

	TID_ALREADY_REGISTERED=`echo "$examLogoutLink" | grep -o "tid=$TID"`

	if test "$TID_ALREADY_REGISTERED"; then
		echo "That exam is already registered :)"
		exit 0
	fi
}

registerExamWithTID() {
	local regLink=$(echo "$examPart" | hxselect -cs "\n" "div.m_podnadpis" | grep "přihlásit" | grep "tid=$TID" | awk 'BEGIN{FS="\""}{print $2}' | hxunent)

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

parseApidURL

SUBJECT=$(echo $examPart | hxselect -cs "\n" "div.m_nadpis span.hlavni")
if [ ! "$examPart" ]; then
	echo "No exams published yet .."
	exit 2001
fi


# Now we have three possibilities:
# Not logged in anywhere -> log into the first exam available ..
# Logged in somewhere -> determine if there are any free slots in preceding exams

if [ ! "$examLogoutLink" ]; then
	# 1st scenario
	registerExamWithTID
	exit $?
else
	# 2nd scenario ..

	examsInfos=$(echo $examPart | hxselect -s "\n" "div.m_tinfo")
	examsCount=$(echo "$examsInfos" | wc -l)

	# Iterate over the exam infos .. :)
	for (( i=1; i < $examsCount; ++i )); do

		currLine=$(echo "$examsInfos" | sed -n ${i}p)

		isGoodTID=`echo $currLine | grep -o "$TID"`

		if test -z "$isGoodTID"; then
			continue;
		fi

		isWithoutSlots=$(echo $currLine | grep m_nespl_pod)

		if [ ! "$isWithoutSlots" ]; then
			# We have found better exam slot !! :D
			# Logout from the current registered slot & register this one !
			URL="https://www.vutbr.cz/studis/$examLogoutLink"
			parseURL

			parseApidURL

			registerExamWithTID
			exit $?

		else
			echo "Na zvoleném termínu ze zkoušky z '$SUBJECT' stále není volné místo :/"
			exit 1
		fi

	done
fi

echo "Ukončuji tento skript neboť dospěl do nedefinovaného bodu. Vracím 0 !!"
exit 0
