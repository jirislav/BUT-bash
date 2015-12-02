# BUT-bash
It serves to obtain bash access to https://www.vutbr.cz/ logged in account securely

# Prerequisities installation
  `sudo apt-get install bash grep curl awk http-xml-utils`

# Usage
This will repeat the BASH script called "final-exam-reRegister.sh" every 10 seconds with one argument "160569" until it succeeds:
  `./loopThrough.sh 10 final-exam-reRegister.sh 160569`

