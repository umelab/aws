#!/bin/bash

# ##############################################
# Variables
# ##############################################
# 大阪
AWS_DEFAULT_REGION='ap-northeast-3'
# security group name
EC2_SECURITY_GROUP_NAME='default-umeda-security-group'
# security group description
EC2_SECURITY_GROUP_DESCRIPTION='security group for default-umeda-vpc'
# security group tag strings
STRING_EC2_SECURITY_GROUP_TAG="ResourceType=security-group,Tags=[{Key=Name,Value=${EC2_SECURITY_GROUP_NAME}}]"
# protocol
EC2_SECURITY_GROUP_PROTOCOL='tcp'
# port
EC2_SECURITY_GROUP_PORT='80'
# cidr
EC2_SECURITY_GROUP_CIDR='0.0.0.0/0'
# vpc id
EC2_VPC_ID=''
# security group id
EC2_SECURITY_GROUP_ID=''

# ##############################################
# check args
# ##############################################
if [ $# -ne 1 ]; then
    echo "Usage: $0 <vpc-id>"
    exit 1
else
    EC2_VPC_ID=$1
fi

# ##############################################
# create security group
# ##############################################
RET=`aws ec2 create-security-group --group-name "${EC2_SECURITY_GROUP_NAME}" --description "${EC2_SECURITY_GROUP_DESCRIPTION}" --vpc-id "${EC2_VPC_ID}" --tag-specifications "${STRING_EC2_SECURITY_GROUP_TAG}"`

ISSUCCESS=$?
# check result
if [ ${ISSUCCESS} -ne 0 ]; then
    echo "Failed to create security group."
    exit 1
fi

# ##############################################
# get security group id
# ##############################################
EC2_SECURITY_GROUP_ID=`echo ${RET} | jq -r '.GroupId'`

# ##############################################