#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

echo "$(date +%s) start"

# Login using API keys
bw login --apikey

# set BW_SESSION variable to a valid token
export BW_SESSION=$(bw unlock $BW_PASSWD --raw)

# set GLG Organization ID
export BW_ORG_ID=$(bw list organizations | jq -r '.[] | . as $parent | .id')

# export all entries
EXPORT_DIR="/tmp/export"
mkdir "${EXPORT_DIR}"
bw export --organizationid $BW_ORG_ID --output "${EXPORT_DIR}/vault.json" --format json


# per entry, check if they contain attachments and then export them
bw list items --session $BW_SESSION | jq -r '.[] | select(.attachments != null) | . as $parent | .attachments[] | "bw get attachment --session $BW_SESSION \(.id) --itemid \($parent.id) --output \"./export/attachments/\($parent.name)/\(.fileName)\""'

# clear Bitwarden session
bw logout

# create an archive with all exported data
tar czvf bw-backup.tar.gz "${EXPORT_DIR}"
ls -l *.gz


# Upload backup to S3
#aws s3 cp $EXPORT_NAME.tar.gz s3://bw-vault-backup/$EXPORT_NAME.tar.gz
echo "$(date +%s) end"
