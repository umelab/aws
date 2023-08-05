#!/bin/bash

# #############################################
# This script is used to create an internet gateway
#  1. check vpc is exist
#  2. check internet gateway is exist
#  3. create internet gateway
#  4. attach internet gateway to vpc
#  5. get internet gateway information
#
# How to use:
#  $ ./create_igw.sh <vpc-id>
#
# @auther: eizo umeda
# @date: 2023/08/05
# ##############################################

# ##############################################
# Variables
# ##############################################
# 大阪
AWS_DEFAULT_REGION='ap-northeast-3'
# internet gateway name
EC2_IGW_NAME='default-umeda-igw'
# internet gateway tag strings
STRING_EC2_IGW_TAG="ResourceType=internet-gateway,Tags=[{Key=Name,Value=${EC2_IGW_NAME}}]"
# vpc id
EC2_VPC_ID=''
# internet gateway id
EC2_IGW_ID=''
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
RET=`aws ec2 describe-vpcs --filters Name=vpc-id,Values=${EC2_VPC_ID} | jq -r '.Vpcs[].VpcId'`
if [ "$RET" != ${EC2_VPC_ID} ]; then
    echo "VPC is not exist."
    exit 1
fi

# ##############################################
# check internet gateway is exist
# ##############################################
RET=`aws ec2 describe-internet-gateways --filters Name=tag:Name,Values=${EC2_IGW_NAME} | jq -r '.InternetGateways[].InternetGatewayId'`
if [ "$RET" != "" ]; then
    echo "Internet Gateway is already exist."
    exit 1
fi

# ##############################################
# create internet gateway
# ##############################################
RET=`aws ec2 create-internet-gateway --tag-specifications ${STRING_EC2_IGW_TAG}`
ISSUCCESS=$?
# check result
if [ ${ISSUCCESS} -ne 0 ]; then
    echo "Failed to create internet gateway."
    exit 1
fi

# ##############################################
# get internet gateway id
# ##############################################
EC2_IGW_ID=`echo ${RET} | jq -r '.InternetGateway.InternetGatewayId'`
EC2_IGW_NAME=`echo ${RET} | jq -r '.InternetGateway.Tags[].Value'`

# ##############################################
# attach internet gateway to vpc
# ##############################################
RET=`aws ec2 attach-internet-gateway --internet-gateway-id ${EC2_IGW_ID} --vpc-id ${EC2_VPC_ID}`
ISSUCCESS=$?
# check result
if [ ${ISSUCCESS} -ne 0 ]; then
    echo "Failed to attach internet gateway to vpc."
    exit 1
fi

# ##############################################
# get internet gateway information
# ##############################################
RET=`aws ec2 describe-internet-gateways --filters Name=tag:Name,Values=${EC2_IGW_NAME}`
# get internet gateway id
EC2_IGW_ID=`echo ${RET} | jq -r '.InternetGateways[].InternetGatewayId'`
# get internet gateway state
EC2_IGW_STATE=`echo ${RET} | jq -r '.InternetGateways[].Attachments[].State'`
# get internet gateway vpc id
EC2_IGW_VPC_ID=`echo ${RET} | jq -r '.InternetGateways[].Attachments[].VpcId'`

# ##############################################
# output
# ##############################################
echo "*** Internet Gateway Information ***"
echo "Internet Gateway Name: ${EC2_IGW_NAME}"
echo "Internet Gateway ID: ${EC2_IGW_ID}"
echo "Internet Gateway State: ${EC2_IGW_STATE}"
echo "Internet Gateway VPC ID: ${EC2_IGW_VPC_ID}"
echo "***********************"

# ##############################################
# end of file
# ##############################################