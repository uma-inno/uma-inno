#!/bin/bash

#
# Resource request (no access token)
#

INIT_REQUEST=$(curl http://inno2-bif4-p1-s25.cs.technikum-wien.at/<placeholder>);

TICKET_1=$(echo $INIT_REQUEST | grep -oP 'ticket=\K[^&]*');

AS_URI=$(echo $INIT_REQUEST | grep -oP 'as_uri=\K[^&]*');


# Should return 401 + header with realm name + permission ticket (ticket) + auth server location (as_uri) 
echo "$INIT_REQUEST";
echo "\n\n";


read -n 1 -s -r -p "\nPress any key to continue...";

#
# RPT request with permission ticket
#

RPT_REQUEST=$(curl -d  "grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Auma-ticket&ticket=$TICKET_1" http://inno2-bif4-p1-s25.cs.technikum-wien.at/<placeholder>);

TICKET_2=$(echo $RPT_REQUEST | grep -oP 'ticket=\K[^&]*');

CLAIMS=$(curl -X GET http://inno2-bif4-p1-s25.cs.technikum-wien.at/<placeholder>);










#
#
#





