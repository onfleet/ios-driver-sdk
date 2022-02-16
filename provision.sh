#!/usr/bin/env bash

#  provision.sh
#  OnfleetDriverSDK
#
#  Created by Peter Stajger on 17/11/2021.
#  Copyright © 2021 Onfleet Inc. All rights reserved.

set -e

if [ -z "${4}" ]; then
cat << EOM
failed: one or more parameters are missing

Completes the provisioning process on iOS simulators.

The script should be used when a driver is logging in using the simulator and
this output is printed into debug console:

PLEASE INSERT PRIVATE KEY WITHIN NEXT XY SECONDS

Usage: ./provision.sh <API key> <application id> <bundle id> <phone number>

    API key
            The API key can be obtained from the Onfleet Dashboard. It is used to
            authenticate calls against Onfleet\'s API.
    application id
            The id of your application provided by Onfleet platform.
    bundle id
            The bundle id of your iOS application. The push notification will
            be delivered into app using this id.
    phone number
            The phone number of driver being provisioned.
            Phone number must be in E.164 format (+14155552671).
            
Provisioning is completed by obtaining privateKey from Onfleet using
driver test accounts. This only applies to organizations who
have the mobileSDK feature.

Test drivers must exist in a single organization for which the sdk/application id
above is provisioned. If an account is test account and the driver is added
to multiple organizations, the account no longer qualifies as a test account.

Similarly, if an account is a test account and the driver is removed from that
organization, the account no longer qualifies as a test account.

If you meet the criteria above and you wish to flag your driver account as test
account, please contact Onfleet support at support@onfleet.com.

Note:
	If you encounter error ResourceNotFound (1402) while executing the provision script
	it most likely means that your account is not flagged as test account.

EOM
    exit 1
fi

API_KEY="$1"
APPLICATION_ID="$2"
BUNDLE_ID="$3"
PHONE_NUMBER=$(echo "$4" | sed -r 's/[+]+/%2B/g')

RESPONSE=$(curl -X GET "https://onfleet.com/api/v2/workers/$PHONE_NUMBER/testAccountPrivateKey/$APPLICATION_ID" -u "$API_KEY:" --silent)
PARSED_RESPONSE=$(echo $RESPONSE | python3 -c "
import sys, json;
try:
    payload = json.load(sys.stdin)
    if 'code' in payload:
        msg = 'failed: {} - ({}) {}'; print(msg.format(payload['code'], payload['message']['error'], payload['message']['message']))
    elif 'privateKey' in payload:
        print(payload['privateKey'])
    else:
        print('failed: unexpected response from server')
except:
    print('failed: unexpected response from server')
")

if [[ "$PARSED_RESPONSE" =~ ^failed:.* ]]; then
    echo $PARSED_RESPONSE
    exit 1
fi

PRIVATE_KEY="$PARSED_RESPONSE"
if [ -z "${PRIVATE_KEY}" ]; then
    echo "failed: no private key found"
    exit 1
fi

BOOTED_DEVICE_ID=$(xcrun simctl list devices booted | grep -i booted | cut -d "(" -f2 | cut -d ")" -f1)
if [ -z "${BOOTED_DEVICE_ID}" ]; then
    echo "failed: no booted device found"
    exit 1
fi

ISSUED_AT=$(date +%s)

echo '{
    "aps" : {
        "alert": "Provisioning Device"
    },
    "action": "provision",
    "privateKey": "'$PRIVATE_KEY'",
    "issuedAt": '$ISSUED_AT'
}' | xcrun simctl push "$BOOTED_DEVICE_ID" "$BUNDLE_ID" -
