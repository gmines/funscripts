#!/bin/bash
set -x # verbose output for debug

# VARS
mydomain="loftlabs.ca"
hosts=("prometheus" "vpn" "mx1")
gdapikey="9u51mB4Foqy_8Krx9hvrBUp6CyRZ5Q76oJ:VELx5mfHYZot9Um2LZLXQn"
logdest="local7.info"

#myip=`curl -s "https://api.ipify.org"`
myip=$(curl http://checkip.amazonaws.com/)

# Sanity Check(s)
#validate IP address (makes sure DNS doesn't get updated with a malformed payload)
if [[ ! $myip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        exit 1
fi


# Script Block
for hostname in ${hosts[@]} ;
do
    dnsdata=`curl -s -X GET -H "Authorization: sso-key ${gdapikey}" "https://api.godaddy.com/v1/domains/${mydomain}/records/A/${hostname}"`
    gdip=`echo $dnsdata | cut -d ',' -f 1 | tr -d '"' | cut -d ":" -f 2`
    
    echo "`date '+%Y-%m-%d %H:%M:%S'` - Current External IP is $myip, GoDaddy DNS IP is $gdip"

    if [ "$gdip" != "$myip" -a "$myip" != "" ]; then
        echo "IP has changed!! Updating on GoDaddy"
        curl -s -X PUT "https://api.godaddy.com/v1/domains/${mydomain}/records/A/${hostname}" -H "Authorization: sso-key ${gdapikey}" -H "Content-Type: application/json" -d "[{\"data\": \"${myip}\"}]"
        logger -p $logdest "Changed IP on ${hostname}.${mydomain} from ${gdip} to ${myip}"
    fi
done

