#!/bin/bash

# Query Metadata for deployment details:
ADMIN_NAME=$(curl -s 169.254.169.254/latest/user-data | yq -r .users[0].name)
exports=$(curl -s 169.254.169.254/latest/user-data | yq -r '.ipsec | to_entries[] | "export " + .key + "=" + (.value | tostring)')
eval $exports

# Add admin user to the docker group
usermod -a -G docker ${ADMIN_NAME}

# Get strongSwan container image version (tag)
SWAN_VER=$(docker image ls strongswan --format "{{.Tag}}")

# Create strongSwan container
docker create --name=strongswan --hostname=$(hostname) --network=host \
--cap-add=NET_ADMIN --cap-add=SYS_ADMIN --cap-add=SYS_MODULE \
--env remote_ip="${remote_ip}" \
--env policy_name="${policy_name}" \
--env ike_proposal="${ike_proposal}" \
--env esp_proposal="${esp_proposal}" \
--env preshared_key="${preshared_key}" \
--env STRONGSWAN_CONF=/etc/strongswan.conf \
--restart always \
strongswan:$SWAN_VER
docker start strongswan

# Prepare a shared volume for both containers
mkdir -p /opt/webhc
mount -t tmpfs tmpfs /opt/webhc -o size=1m

# Create Web-HC container
WEBHC_VER=$(docker image ls web-hc --format "{{.Tag}}")
docker create --name=web-hc --hostname=web-hc \
--network=host \
--volume=/opt/webhc:/var/www/local \
--restart always \
web-hc:$WEBHC_VER
docker start web-hc

# Update Routing table with target routes
/usr/local/bin/update-routes.sh

# Check route updates for every ... minutes
(crontab -l; echo "*/15 * * * * /usr/local/bin/update-routes.sh") | sort -u | crontab -
