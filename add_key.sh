#! /bin/bash

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
# $4 YES answer 
confirm_or_die(){

    echo "$1"
    echo "default: $3"
    echo "confirm: $4"

    read ANS
    #lowercase ANS
    ANS=${ANS,,}
    
    if [[ -z "$ANS" ]] ; then
        [[ "$3" == "$4" ]] || die "$2"
    else
        [[ "$ANS" == "$3" ]] || die "$2"
    fi
}


#test internet connection, and given url
#if test fail ask the user what to do
check_url(){

    test_url "$1"
    tmp="$?"
    
    if [[ "$tmp" == "$NO_INTERET" ]] ; then
        confirm_or_die "there's no internet connection, continue without testing $1?" "no test available" "Y" "Y"
     elif [[ "$tmp" == "$NOT_REACHABLE_HOST" ]] ; then
        confirm_or_die "$1 is unreachable, but there's internet connection, continue anyway?" "$1 in not valid" "N" "Y"
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
    true
elif [[ "$HOSTNAME" =~ ([a-zA-Z]([a-zA-Z]\.)+[a-zA-Z]) ]]; then
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
    
echo -n "Insert user name(can be empty): "
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
