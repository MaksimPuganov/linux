#!/bin/bash

AMI_NAME="SNI Proxy"
INSTANCE_NAME=SNI_Proxy_Server
INSTANCE_TYPE=t1.micro
KEY_NAME=aws_id_rsa
SECURITY_GROUP="DNS_Security_Group"

UK_REGION=eu-west-1
US_REGION=us-east-1

function findInstance() {
	NAME=$1
	STATE=$2
	
	if [ "$STATE" != "" ]; then
		INSTANCE_ID=$(aws ec2 describe-instances --output text --filters "Name=tag:Name,Values=$NAME" "Name=instance-state-name,Values=$STATE" --region $REGION --query "Reservations[].Instances[].InstanceId")
	else
		INSTANCE_ID=$(aws ec2 describe-instances --output text --filters "Name=tag:Name,Values=$NAME" --region $REGION --query "Reservations[].Instances[].InstanceId")
	fi

	if [ $? -eq 0 ]; then
		echo $INSTANCE_ID
		return 0
	else
		echo "Command failed"
		exit 1
	fi
}

function createAndStartInstance() {
	NAME=$1

	IMAGE_ID=$(aws ec2 describe-images --output text --region $REGION --filters "Name=name,Values=$AMI_NAME" --query "Images[0].ImageId")
	if [ $? -ne 0 ]; then
		echo "Command failed"
		exit 1
	fi
	
	echo "INFO: Found Image $IMAGE_ID for $AMI_NAME"
	INSTANCE_ID=$(aws ec2 run-instances --output text --image-id $IMAGE_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-groups "$SECURITY_GROUP" --region $REGION --query "Instances[].InstanceId" --instance-initiated-shutdown-behavior terminate)
	if [ $? -eq 0 ]; then
		aws ec2 create-tags --resources $INSTANCE_ID --tag "Key=Name,Value=$NAME" --region $REGION
		if [ $? -ne 0 ]; then
			echo "Failed to tag instance with id $INSTANCE_ID"
			exit 1
		fi

		echo "INFO: Waiting for new instance $INSTANCE_ID to be running"

		aws ec2 wait instance-running --region $REGION --instance-id $INSTANCE_ID
		if [ $? -eq 0 ]; then
			IP_ADDRESS=$(aws ec2 describe-instances --output text --region $REGION --instance-id $INSTANCE_ID --query "Reservations[].Instances[].[PublicIpAddress	]")
			echo "Instance $INSTANCE_ID is now running and available at $IP_ADDRESS"
		else
			echo "Failed to wait for instance with id $INSTANCE_ID to be running"
			exit 1
		fi
	else
		echo "Failed to create instance!"
		exit 1
	fi
}

OPERATION=query
if [ $# -eq 2 ]; then
	case "$1" in
		"-create") OPERATION=create ;;
		"-destroy") OPERATION=destroy ;;
		"-query") OPERATION=query ;;
	esac
	
	if [ "$3" = "UK" ]; then
		REGION=$UK_REGION
	else
		REGION=$US_REGION
	fi

	if [ "$OPERATION" = "destroy" ]; then
		INSTANCE_ID=$(findInstance "$INSTANCE_NAME" pending,running,stopping,stopped)
		if [ "$INSTANCE_ID" != "" ]; then
			aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION > /dev/null
			if [ $? -eq 0 ]; then
				echo "INFO: Instance $INSTANCE_ID terminated"
			else
				echo "ERROR: Failed to terminate instance, see previous messages"
				exit 2
			fi
		else
			echo "ERROR: No instance found"
			exit 1
		fi
	elif [ "$OPERATION" = "create" ]; then
		INSTANCE_ID=$(findInstance "$INSTANCE_NAME" pending,running,stopping,stopped)
		if [ "$INSTANCE_ID" = "" ]; then
			createAndStartInstance $INSTANCE_NAME
		else
			echo "ERROR: An existing $INSTANCE_NAME exists in an unknown state"
			exit 2
		fi
	else # query
		RESULT=$(aws ec2 describe-instances --region $REGION --filters "Name=tag:Name,Values=$INSTANCE_NAME" --query 'Reservations[0].Instances[0].{InstanceId:InstanceId,State:State.Name,IpAddress:PublicIpAddress}')
		if [ $? -eq 0 ]; then
			if [ "$RESULT" != "null" ]; then
				INSTANCE_ID=`echo $RESULT | jq -r .InstanceId`
				STATE=`echo $RESULT | jq -r .State`
				if [ "$STATE" = "running" ]; then
					IP_ADDRESS=$(echo $RESULT | jq -r .IpAddress)
					echo "Instance $INSTANCE_ID is running and available at $IP_ADDRESS"
				else
					echo "Instance $INSTANCE_ID is $STATE"
				fi
			else
				echo "No instance found in $REGION"
				exit 1
			fi
		else
			echo "ERROR: Failed to query instance"
			exit 2
		fi
	fi
else
	echo "Usage: `basename $0`: <-create|-destroy|-query> <US or UK>"
	exit 1
fi

