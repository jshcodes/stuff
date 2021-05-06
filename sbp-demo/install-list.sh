#!/bin/bash
TAGNAME="_demo-purpose"
res=$(aws ec2 describe-instances \
    --query "Reservations[*].Instances[*].{Name: Tags[?Key=='$UNIQUE_ID$TAGNAME'] | [0].Value, InstanceID: InstanceId}" \
    --filter {"Name=instance-state-name,Values=running","Name=tag-key,Values=$UNIQUE_ID$TAGNAME"} \
    --region $REGION --output json)

thing=$(echo "${res}" | jq -r '.[] | @base64')
for row in $thing; do
	_jq(){
		echo ${row} | base64 --decode | jq -r .[].InstanceID
	}
	echo $(_jq)
done