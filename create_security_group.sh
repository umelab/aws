#!/bin/bash

# #############################################
# This script is used to create a security group
#  1. check vpc is exist
#  2. check security group is exist
#  3. create security group
#  4. get security group information
#
# How to use:
#  $ ./create_security_group.sh <vpc-id>
#
# @auther: eizo umeda
# @date: 2023/08/05
# ##############################################

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
# check vpc is exist
# ##############################################
RET=$(aws ec2 describe-vpcs \
    --filters 'Name=vpc-id,Values='"${EC2_VPC_ID}" \
    | jq -r '.Vpcs[].VpcId' \
    )
if [ "$RET" != ${EC2_VPC_ID} ]; then
    echo "VPC is not exist."
    exit 1
fi

# ##############################################
# check security group is exist
# ##############################################
RET=$(aws ec2 describe-security-groups \
    --filters 'Name=tag:Name,Values='"${EC2_SECURITY_GROUP_NAME}" \
    | jq -r '.SecurityGroups[].GroupId')

if [ "$RET" != "" ]; then
    echo "Security Group is already exist."
    exit 1
fi

# ##############################################
# create security group
# ##############################################
RET=$(aws ec2 create-security-group \
    --group-name "${EC2_SECURITY_GROUP_NAME}" \
    --description "${EC2_SECURITY_GROUP_DESCRIPTION}" \
    --vpc-id "${EC2_VPC_ID}" \
    --tag-specifications "${STRING_EC2_SECURITY_GROUP_TAG}" \
    )

ISSUCCESS=$?
# check result
if [ ${ISSUCCESS} -ne 0 ]; then
    echo "Failed to create security group."
    exit 1
fi
EC2_SECURITY_GROUP_ID=`echo ${RET} | jq -r '.GroupId'`

# echo "security_group_id:"${EC2_SECURITY_GROUP_ID}
# echo "protocol:"${EC2_SECURITY_GROUP_PROTOCOL}
# echo "port:"${EC2_SECURITY_GROUP_PORT}
# echo "cidr:"${EC2_SECURITY_GROUP_CIDR}
# echo "tag:"${STRING_EC2_SECURITY_GROUP_TAG}

# #############################################
# add ingress rule
# #############################################
RET=$(aws ec2 authorize-security-group-ingress \
    --group-id "${EC2_SECURITY_GROUP_ID}" \
    --protocol "${EC2_SECURITY_GROUP_PROTOCOL}" \
    --port "${EC2_SECURITY_GROUP_PORT}" \
    --cidr "${EC2_SECURITY_GROUP_CIDR}" \
    )
ISSUCCESS=$?
# check result
if [ ${ISSUCCESS} -ne 0 ]; then
    echo "Failed to add ingress rule."
    exit 1
fi

# ##############################################
# output
# ##############################################
echo "*** Security Group Information ***"
echo "VPC ID: ${EC2_VPC_ID}"
echo "Security Group Name: ${EC2_SECURITY_GROUP_NAME}"
echo "Security Group ID: ${EC2_SECURITY_GROUP_ID}"
echo "***********************"
# ##############################################
