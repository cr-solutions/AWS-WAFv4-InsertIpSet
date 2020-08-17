#!/bin/bash

#####################################################################################

REGION="eu-west-1"
DESC="IPs to block"

NAME="Manually_IPv4"
ID="de5aee1f-4015-488e-950a-c951ae9063b7"

NAME_v6="Manually_IPv6"
ID_v6="fd7ed4dd-fe46-4bff-9d20-a67988ca7741"


#####################################################################################

# The contents of this file are subject to the Mozilla Public License
# Version 2.0 (the "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
# https://www.mozilla.org/en-US/MPL/2.0/

# Software distributed under the License is distributed on an "AS IS" basis,
# WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
# the specific language governing rights and limitations under the License.

# The Initial Developers of the Original Code are:
# Copyright (c) 2020, CR-Solutions (https://www.cr-solutions.net), Ricardo Cescon (https://cescon.de)
# All Rights Reserved.

if [ -z "$1" ] || [ "$1" == "help" ] ; then
  me=`basename "$0"`
  echo 
  echo "add an new IP to IP sets or remove an existing"
  echo "Sample Call: ./$me <ip>"
  echo "   or"
  echo "Sample Call: ./$me <ip> remove"
  echo
  exit
fi

REMOVE_IP=false
if [ "$2" == "remove" ] ; then
   REMOVE_IP=true
fi


TMP="/tmp/ip_set.out"
BLOCK="32"

regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$'
IP="$1"

# check for IPv6
if [[ $var =~ $regex ]]; then
    NAME="$NAME_v6"    
    ID="$ID_v6"
    BLOCK=128
fi

#####################################################################################

# Get IP set
aws wafv2 get-ip-set --name=$NAME --scope REGIONAL --id=$ID --region $REGION > $TMP

# Get token from the JSON
LOCK_TOKEN=$(jq -r '.LockToken' $TMP)

# Get IP list from the JSON
arr=( $(jq -r '.IPSet.Addresses[]' $TMP) )

if [ "$REMOVE_IP" = true ]; then
   # Remove our ip to the list
   to_del="${IP}/${BLOCK}"
   arr=( "${arr[@]/$to_del}" )
   # trim string with xargs
   ADD=$(echo "${arr[@]}" | xargs)
else
   # Add our ip to the list
   arr+=( "${IP}/${BLOCK}" )
   ADD="${arr[@]}"
fi

echo
echo "IP Set:"
echo "$ADD"
echo 

# Update IP set
aws wafv2 update-ip-set --name=$NAME --scope=REGIONAL --id=$ID --addresses $ADD --lock-token=$LOCK_TOKEN --region=$REGION --description="$DESC"