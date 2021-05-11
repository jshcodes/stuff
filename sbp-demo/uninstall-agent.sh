payload='[{"Key":"InstanceIds","Values":["'$INSTANCE_ID'"]}]'
result=$(aws ssm send-command --document-name "AWS-ConfigureAWSPackage" \
	--document-version "1" --targets $payload \
	--parameters '{"action":["Uninstall"],"installationType":["Uninstall and reinstall"],"name":["'$PACKAGE_NAME'"],"version":[""],"additionalArguments":["{}"]}' \
	--timeout-seconds 600 --max-concurrency "50" --max-errors "0" --region $REGION | jq .[].ErrorCount)
if [[ "$result" == 0 ]]
then
    echo "Sensor removal has been requested. Please allow 30 seconds for the process to complete."
else
    echo "An error occurred while requesting the sensor uninstall."
fi