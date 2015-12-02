#!/bin/bash

DIR="$(dirname $0)"

configFileName="$DIR/config"

# Load the config
if [ -f "$configFileName" ]; then
	source "$configFileName"
else
	echo "Config not found at '$configFileName'!"
	exit 1000
fi

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
	hiddenData=$(hxnormalize -edxL "$html" | hxselect -s '\n' "input[type=hidden]" | egrep -v "name=\"type|name=\"hact" |  awk 'BEGIN{ORS="&"; FS="\""}{print $2"="$6}')

	# Check if we have not already the html containing the hidden inputs
	if [ -z "$(echo "$hiddenData" | grep fdkey)" ]; then

		# no .. we don't :)
		URL="https://www.vutbr.cz/login/"
		curl -Lc "$cookieA" "$URL" > "$html"
		hiddenData=$(hxnormalize -edxL "$html" | hxselect -s '\n' "input[type=hidden]" | egrep -v "name=\"type|name=\"hact" |  awk 'BEGIN{ORS="&"; FS="\""}{print $2"="$6}')

		# ouch! probably bad login URL?
		if [ -z "$(echo "$hiddenData" | grep fdkey)" ]; then
			echo "Empty FDKEY!"
			exit 1003
		fi
	fi

	# Check the login was in config
	if [ -z "$login" ]; then
		echo "Enter BUT login:"
		read login

		if [ -z "$login" ]; then
			echo "Cannot use empty login!"
			exit 1004
		fi
	else
		echo "Using BUT login from config '$login'"
	fi

	# Prompt for pw
	echo "Enter password:" 
	read -s pw

	if [ -z "$pw" ]; then
		echo "Cannot use empty password!"
		exit 1005
	fi

	data="${hiddenData}LDAPlogin=$login&LDAPpasswd=$pw"
	URL="https://www.vutbr.cz/login/in"

	justDoPOST
}

justDoPOST() {
	tmpHtml="$html"
	html="/dev/null"
	parseURLWithDataPOST
	html="$tmpHtml"
}

assertURLnotEmpty() {

	if [ -z "$URL" ]; then
		echo "Cannot do request on unknown URL!"
		exit 1001
	fi
}

assertDataNotEmpty() {

	if [ -z "$data" ]; then
		echo "Cannot do POST with no data!"
		exit 1002
	fi
}

htmlHasLoginForm() {

	if [ ! -z "$(hxnormalize -edxL "$html" | hxselect -s "\n" "form#login_form")" ]; then
		return 0 # True :D
	else
		return 1 # False :D
	fi
}

parseURLWithDataPOST() {

	assertDataNotEmpty
	assertURLnotEmpty

	switchCookies
	curl -Lc "$cookieA" -b "$cookieB" -d "$data" "$URL" > "$html"

	# If returned login form, that means we have to login ..
	htmlHasLoginForm
	if [ $? -eq 0 ] && [ $html != '/dev/null' ]; then
		local tmpDATA="$data"
		local tmpURL="$URL"

		login

		data="$tmpDATA"
		URL="$tmpURL"

		parseURLWithDataPOST
	fi
}

parseURL() {

	assertURLnotEmpty

	switchCookies
	curl -Lc "$cookieA" -b "$cookieB" "$URL" > "$html"

	# If returned login form, that means we have to login ..
	htmlHasLoginForm
	if [ $? -eq 0 ] && [ $html != '/dev/null' ]; then
		local tmpDATA="$data"
		local tmpURL="$URL"

		login

		data="$tmpDATA"
		URL="$tmpURL"

		parseURL
	fi

}
