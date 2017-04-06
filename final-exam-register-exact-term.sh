#!/bin/bash

helperFileName="$(dirname $0)/helper.sh"
source $helperFileName

if test -z "$APID"; then
	APID="$1"
fi

if test -z "$TID"; then
	TID="$2"
fi

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

	possible_exam_parts=$(cat "$html" | hxnormalize -edxL | hxselect -s "\n" "div.page div.m_ppzc" | grep -B6 -A1000 zkoušk | hxnormalize -edxL )

	# Ignore this (was neccessary only for registering the first exam)
	# 
	#if [ "`echo "$possible_exam_parts" | grep m_ppzc | wc -l`" -gt 1 ]; then
	#	# More than 1 type of registrations so cut it to the first one .. TODO resolve this possible bug of wanting to register to all the exams :)
	#	examPart=$(echo "$possible_exam_parts" | grep -B1000 -m 2 m_ppzc | hxnormalize -edxL )
	#else
	#	examPart="$possible_exam_parts"
	#fi
	
	examPart="$possible_exam_parts"
		
	examLogoutLink=$(echo "$examPart" | hxselect -s "\n" "div.m_podnadpis" | grep "odhlásit" | egrep "tid=($TID)" | awk 'BEGIN{FS="\""}{print $2}' | hxunent)

	TID_EXISTS=`echo "$examPart" | egrep -o "$TID"`

	if test -z "$TID_EXISTS"; then
		echo "TID=($TID) not found for APID=$APID !" >&2
		echo "Please check '$APID_URL' and gimme the right TID" >&2
		exit 2
	fi

	TID_ALREADY_REGISTERED=`echo "$examLogoutLink" | egrep -o "tid=($TID)"`

	if test "$TID_ALREADY_REGISTERED"; then
		echo "That exam TID=($TID) is already registered :), see '$APID_URL'"
		exit 0
	fi
}

registerExamWithTID() {
	local regLink=$(echo "$examPart" | hxselect -cs "\n" "div.m_podnadpis" | grep "přihlásit" | egrep "tid=($TID)" | head -n1 | awk 'BEGIN{FS="\""}{print $2}' | hxunent )

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

SUBJECT=$(echo "$examPart" | hxselect -cs "\n" "div.m_nadpis span.hlavni" | head -n1 )
if [ ! "$examPart" ]; then
	echo "No exams published yet .."
	exit 2001
fi


examsInfos=$(echo $examPart | hxselect -s "\n" "div.m_tinfo" | egrep "$TID")

if test -z "$examsInfos"; then
	echo "Nenašel jsem kombinaci APID=$APID && TID=($TID) ! Zkontrolujte prosím '$APID_URL'" >&2
	exit 2
fi

examsCount=$(echo "$examsInfos" | wc -l)

echo "Found $examsCount exams totally"
# Iterate over the exam infos .. :)
for (( i=1; i <= $examsCount; ++i )); do

	echo processing $i
	currLine=$(echo "$examsInfos" | sed -n ${i}p)

	CURRENT_TID=`echo $currLine | egrep -o "tid=($TID)"`

	if test -z "$CURRENT_TID"; then
		continue;
	fi

	isWithoutSlots=$(echo $currLine | grep m_nespl_pod)

	if [ ! "$isWithoutSlots" ]; then

		# We cannot logout from found slot, because it could be from another exams group !!

		#if test "$examLogoutLink"; then
		#	# We have found better exam slot !! :D
		#	# Logout from the current registered slot & register this one !
		#	URL="https://www.vutbr.cz/studis/$examLogoutLink"
		#	parseURL

		#	parseApidURL
		#fi

		registerExamWithTID
		if test $? -eq 0; then
			exit 0
		else
			echo "Buď byl někdo rychlejší, nebo se něco stalo špatně .. předpokládal jsem, že na tomto termíu je volno ($CURRENT_TID), ale registrace se nepovedla? wtf??"
		fi


	else
		echo "Na termínu ($CURRENT_TID) zkoušky z '$SUBJECT' stále není volné místo :/"
	fi

done

echo "Na žádném z termínů není volno :/"
exit 1
