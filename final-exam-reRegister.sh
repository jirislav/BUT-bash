#!/bin/bash

DIR="$(dirname $0)"

config="$DIR/config"

cookieA="$DIR/.cookieA"
cookieB="$DIR/.cookieB"
html="$DIR/.html"

switchCookies() {
	tmp="$cookieA"
	cookieA="$cookieB"
	cookieB="$tmp"
}

login() {

	# Get the required generated hidden intputs
	URL="https://www.vutbr.cz/login/"
	curl -Lc "$cookieA" "$URL" > "$html"
	hiddenData=$(hxnormalize -edxL "$html" | hxselect -s '\n' "input[type=hidden]" | egrep -v "name=\"type|name=\"hact" |  awk 'BEGIN{ORS="&"; FS="\""}{print $2"="$6}')

	if [ -z "$(echo "$hiddenData" | grep fdkey)" ]; then
		echo "Empty FDKEY!"
		exit 1
	fi

	# Load the login id
	if [ -f "config" ]; then
		source "$config"
	fi

	if [ -z "$login" ]; then
		echo "Enter BUT login:"
		read -s login

		if [ -z "$login" ]; then
			echo "Cannot use empty login!"
			exit 2
		fi
	else
		echo "Using BUT login from config '$login'"
	fi

	# Prompt for pw
	echo "Enter password:" 
	read -s pw

	if [ -z "$pw" ]; then
		echo "Cannot use empty password!"
		exit 2
	fi

	data="${hiddenData}LDAPlogin=$login&LDAPpasswd=$pw"
	URL="https://www.vutbr.cz/login/in"

	getHtmlWithDataPOST
}

justDoPOST() {
	tmpHtml="$html"
	html="/dev/null"
	getHtmlWithDataPOST
	html="$tmpHtml"
}

assertURLnotEmpty() {

	if [ -z "$URL" ]; then
		echo "Cannot do request on unknown URL!"
		exit 4
	fi
}

assertDataNotEmpty() {

	if [ -z "$data" ]; then
		echo "Cannot do POST with no data!"
		exit 3
	fi
}

getHtmlWithDataPOST() {

	assertDataNotEmpty
	assertURLnotEmpty

	switchCookies
	curl -Lc "$cookieA" -b "$cookieB" -d "$data" "$URL" > "$html"
}

getHtml() {

	assertURLnotEmpty

	switchCookies
	curl -Lc "$cookieA" -b "$cookieB" "$URL" > "$html"
}

login

if [ -z "$1" ]; then
	echo "No apid provided !"
	exit 3
fi

# Set first argument to the apid of the subject to reRegister into
URL="https://www.vutbr.cz/studis/student.phtml?sn=terminy_zk&apid=$1"
getHtml

