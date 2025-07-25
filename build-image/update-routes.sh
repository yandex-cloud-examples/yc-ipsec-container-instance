#!/bin/bash

# =================================
# Update SGW Routes for Remote site
# =================================

WD="/tmp"

# Get current prefix list for ipsec0
ip r show dev ipsec0 | awk '{print $1;}' > $WD/cur-pfx.txt

# Get prefix list from the VM Metadata (User-data)
curl -s -H Metadata-Flavor:Google 169.254.169.254/computeMetadata/v1/instance/attributes/ipsec | yq -r '.remote_subnets' | tr "," "\n" > $WD/new-pfx.txt

# If we have no changes in prefix list -> do nothing
if diff $WD/cur-pfx.txt $WD/new-pfx.txt &>/dev/null; then
  echo "No Changes."
  exit
fi

PFX_ADD=($(diff --changed-group-format='%>' --unchanged-group-format='' $WD/cur-pfx.txt $WD/new-pfx.txt | tr "\n" " "))
PFX_DEL=($(diff --changed-group-format='%<' --unchanged-group-format='' $WD/cur-pfx.txt $WD/new-pfx.txt | tr "\n" " "))

if [ "${#PFX_ADD[@]}" -gt 0 ]; then
  for PFX in ${PFX_ADD[@]}; do
    echo ip route add $PFX dev ipsec0
    ip route add $PFX dev ipsec0
  done
fi

if [ "${#PFX_DEL[@]}" -gt 0 ]; then
  for PFX in ${PFX_DEL[@]}; do
    echo ip route del $PFX dev ipsec0
    ip route del $PFX dev ipsec0
  done
fi

# Clean up
rm -f $WD/cur-pfx.txt
rm -f $WD/new-pfx.txt

exit