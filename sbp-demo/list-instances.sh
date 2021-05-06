#!/bin/bash
TAGNAME="_demo-purpose"
aws ec2 describe-instances \
    --query "Reservations[*].Instances[*].{Name: Tags[?Key=='$UNIQUE_ID$TAGNAME'] | [0].Value, InstanceID: InstanceId}" \
    --filter {"Name=instance-state-name,Values=running","Name=tag-key,Values=$UNIQUE_ID$TAGNAME"} \
    --region $REGION --output table