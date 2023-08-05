#!/bin/bash

# ##############################################
# This script is used to create a VPC
#  1. check vpc is exist
#  2. create vpc
#  3. get vpc information
# 
# @auther: eizo umeda
# @date: 2023/08/05
# ##############################################

# ##############################################
# Variables
# ##############################################
# 大阪
AWS_DEFAULT_REGION='ap-northeast-3'
# vpc 
EC2_VPC_NAME='default-umeda-vpc'
# CIDR block
EC2_VPC_CIDR='10.0.0.0/16'
# vpc tag strings
STRING_EC2_VPC_TAG="ResourceType=vpc,Tags=[{Key=Name,Value=${EC2_VPC_NAME}}]"

# ##############################################
# aws cli command execution
# ##############################################
# check vps is exist
RET=`aws ec2 describe-vpcs --filters Name=tag:Name,Values=${EC2_VPC_NAME}`
if [ $? -eq 0 ]; then
    echo "VPC is already exist."
    exit 1
fi

# create vpc
RET=`aws ec2 create-vpc --cidr-block ${EC2_VPC_CIDR} --tag-specifications ${STRING_EC2_VPC_TAG}`
ISSUCCESS=$?
# check result
if [ ${ISSUCCESS} -ne 0 ]; then
    echo "Failed to create vpc."
    exit 1
fi

# get vpc id
EC2_VPC_ID=`echo ${RET} | jq -r '.Vpc.VpcId'`
# get vpc state
EC2_VPC_STATE=`echo ${RET} | jq -r '.Vpc.State'`
# get vpc cidr block
EC2_VPC_CIDR_BLOCK=`echo ${RET} | jq -r '.Vpc.CidrBlock'`
# get vpc cidr block association set
EC2_VPC_CIDR_BLOCK_ASSOCIATION_SET=`echo ${RET} | jq -r '.Vpc.CidrBlockAssociationSet'`
# ##############################################
# output
# ##############################################

echo "*** VPC Information ***"
echo "VPC Name: ${EC2_VPC_NAME}"
echo "VPC ID: ${EC2_VPC_ID}"
echo "VPC State: ${EC2_VPC_STATE}"
echo "VPC CIDR Block: ${EC2_VPC_CIDR_BLOCK}"
echo "VPC CIDR Block Association Set: ${EC2_VPC_CIDR_BLOCK_ASSOCIATION_SET}"
echo "***********************"

# ##############################################