#!/bin/bash

exports=$(curl -s 169.254.169.254/latest/user-data | yq -r '.ipsec | to_entries[] | "export " + .key + "=" + (.value | tostring)')
eval $exports
envsubst < /etc/swanctl.tpl > /usr/local/etc/swanctl/swanctl.conf
envsubst < /etc/strongswan.tpl > /etc/strongswan.conf

/charon
