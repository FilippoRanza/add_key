#! /bin/bash
#
#   add_key - helps to generate a ssh key.
#
#   Copyright (c) 2018 Filippo Ranza <filipporanza@gmail.com>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
DEFAULT_KEY_SZ='4096'
DEFAULT_FOLDER="$HOME/.ssh"
DEFAULT_OUTPUT_FILE="$DEFAULT_FOLDER/config"
DEFAULT_PORT_NO='22'

SUCCESS=0
FAILURE=1

NO_INTERET=2
NOT_REACHABLE_HOST=3

TEST_URL='www.google.com'

die(){
    echo "$1"
    exit 1
}

#ping given url 1 time, 1 sec timeout
#returing 0 on success, 1 on failure
nt(){
    if ping  -c 1 "$1" &> /dev/null ; then 
        return "$SUCCESS"
    fi
    return "$FAILURE"
}


#ping TEST_URL, to see if an internet
#connection is available. then ping given URL
#returning an error if this address is not reachable.
test_url(){
    nt "$TEST_URL" || return "$NO_INTERET"
    nt "$1" || return "$NOT_REACHABLE_HOST"
    return "$SUCCESS"
}


#ask the user for something.
#is user answer YES the program continue
#otherwise the program dies
# $1 question
# $2 die message
# $3 default answer
 
confirm_or_die(){
    
    #create default answer help
    DEF_ANS="${3,,}"
    if [[ "$DEF_ANS" == "n" ]] ; then
        ANS_MSG="[y/N]"
    else
        ANS_MSG="[Y/n]"
    fi

    #add, if not present, ?
    echo "$1" | egrep '\?$' &> /dev/null  && QST="$1" || QST="$1?"
    
    echo "$QST$ANS_MSG"

    read ANS
    #lowercase ANS
    ANS="${ANS,,}"
    
    
    ANS="${ANS:-$DEF_ANS}"
    
    [[ "$ANS" == "y" ]] || die "$2"

}


#test internet connection, and given url
#if test fail ask the user what to do
check_url(){

    test_url "$1"
    tmp="$?"
    
    if [[ "$tmp" == "$NO_INTERET" ]] ; then
        confirm_or_die "there's no internet connection, continue without testing $1?" "no test available" "Y"
     elif [[ "$tmp" == "$NOT_REACHABLE_HOST" ]] ; then
        confirm_or_die "$1 is unreachable, but there's internet connection, continue anyway?" "$1 in not valid" "N" 
     fi
}


echo "Generating a new RSA-4096 KEY"

#store name for key file.
echo -n "Insert new key name: "
read KEY

[[  "$KEY" ]] || die "Key file name is mandatory"

#move to DEFAULT_FOLDER and come back
PREV="$PWD"
cd "$DEFAULT_FOLDER"
#check that given name is not already taken
[[ -e "$KEY" ]] && die "$KEY already exist!"

cd "$PREV"

#store Host entry in .ssh/config
echo -n "Insert new Host: "
read HOST

[[ "$HOST" ]] || die "Host is mandatory"
#check that given host is unique
egrep "^(\s+)Host $HOST(\s+)$" "$DEFAULT_OUTPUT_FILE" &> /dev/null && die "$HOST already exist!"

#store host name(url or IP)
echo -n "Insert hostname(url or IP): "
read HOSTNAME

#check that given string is a url or an IP address

if [[ "$HOSTNAME" =~ ((25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9]) ]] ; then
    true 
elif [[ "$HOSTNAME" =~ ((([1-9a-fA-F]{1,4}:){7}|::|([1-9a-fA-F]{1,4}:){1,6}::)([1-9a-fA-F]{1,4})) ]] ; then
    HOSTNAME="${HOSTNAME^^}"
    true
elif [[ "$HOSTNAME" =~ ([a-zA-Z]([a-zA-Z]\.)+[a-zA-Z]) ]]; then
    HOSTNAME="${HOSTNAME,,}"
    check_url "$HOSTNAME"
else 
    die "$HOSTNAME is nor an IPv4, IPv6 or url"
fi



echo -n "Insert port number(empty for 22): "
read PORT_NO

#check that given string is positive number between 1 and 65535 (min and max port number)
if  echo "$PORT_NO" | egrep '^[1-9]+$' &> /dev/null ; then 
    
    (( $N >= 1   )) && ((  $N <= 65535 ))
    
    if (( $? )) ; then
        die "1 < $PORT_NO < 65535 is not true"
    fi
elif [[ "$PORT_NO" ]] ; then 
    die "$PORT_NO is not a number"
fi
    
echo -n "Insert remote user name(can be empty): "
read RUSER

echo -n "A Comment(can be empty):"
read COMMENT

#key generation
ssh-keygen -t rsa -b "$DEFAULT_KEY_SZ" -f "$DEFAULT_FOLDER/$KEY" || die "can't generate a new key"



#add entry in config file
[[ "$COMMENT" ]] &&  echo "#$COMMENT"  >> $DEFAULT_OUTPUT_FILE
echo "#key added on $(date)"  >> $DEFAULT_OUTPUT_FILE
printf "%s\n" "Host $HOST" >> $DEFAULT_OUTPUT_FILE
printf "\t%s\n" "HostName $HOSTNAME" >> $DEFAULT_OUTPUT_FILE
printf "\t%s\n" "Port ${PORT_NO:-$DEFAULT_PORT_NO}" >> $DEFAULT_OUTPUT_FILE
printf "\t%s\n" "User ${RUSER:-$USER}" >> $DEFAULT_OUTPUT_FILE
printf "\t%s\n" "IdentityFile $DEFAULT_FOLDER/$KEY" >> $DEFAULT_OUTPUT_FILE
printf "\n\n\n" >> $DEFAULT_OUTPUT_FILE

echo "Done ;-)"
