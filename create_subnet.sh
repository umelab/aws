#!/bin/bash

# #############################################
# This script is used to create a subnet
#  1. check vpc is exist
#  2. check public subnet is exist
#  3. check private subnet is exist
#  4. create public subnet
#  5. create private subnet
#  6. get subnet information
#
# How to use:
#  $ ./create_subnet.sh <vpc-id>
# 
# @auther: eizo umeda
# @date: 2023/08/05
# ##############################################

# ##############################################
# Variables
# ##############################################
# 大阪
AWS_DEFAULT_REGION='ap-northeast-3'
# public subnet name
EC2_PUBLIC_SUBNET_NAME='default-umeda-public-subnet'
# private subnet name
EC2_PRIVATE_SUBNET_NAME='default-umeda-private-subnet'
# CIDR public subnet
EC2_PUBLIC_SUBNET_CIDR='10.0.0.0/20'
# CIDR private subnet
EC2_PRIVATE_SUBNET_CIDR='10.0.64.0/20'
# public subnet tag strings
STRING_EC2_PUBLIC_SUBNET_TAG="ResourceType=subnet,Tags=[{Key=Name,Value=${EC2_PUBLIC_SUBNET_NAME}}]"
# private subnet tag strings
STRING_EC2_PRIVATE_SUBNET_TAG="ResourceType=subnet,Tags=[{Key=Name,Value=${EC2_PRIVATE_SUBNET_NAME}}]"
# vpc id
EC2_VPC_ID=''

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
if [ $RET != ${EC2_VPC_ID} ]; then
    echo "VPC is not exist."
    exit 1
fi

# ##############################################
# check public subnet is exist
# ##############################################
RET=`aws ec2 describe-subnets --filters Name=tag:Name,Values=${EC2_PUBLIC_SUBNET_NAME} | jq -r '.Subnets[].SubnetId'`
if [ "$RET" = ${EC2_PUBLIC_SUBNET_NAME} ]; then
    echo "Public subnet is already exist."
    exit 1
fi
# ##############################################
# check private subnet is exist
# ##############################################
RET=`aws ec2 describe-subnets --filters Name=tag:Name,Values=${EC2_PRIVATE_SUBNET_NAME} | jq -r '.Subnets[].SubnetId'`
if [ "$RET" = ${EC2_PRIVATE_SUBNET_NAME} ]; then
    echo "Private subnet is already exist."
    exit 1
fi

# ##############################################
# create public subnet
# ##############################################
RET=`aws ec2 create-subnet --vpc-id ${EC2_VPC_ID} --cidr-block ${EC2_PUBLIC_SUBNET_CIDR} --availability-zone ${AWS_DEFAULT_REGION}a --tag-specifications ${STRING_EC2_PUBLIC_SUBNET_TAG}`
ISSUCCESS=$?
# check result
if [ $ISSUCCESS -ne 0 ]; then
    echo "Failed to create public subnet."
    exit 1
fi

# ##############################################
# create private subnet
# ##############################################
RET=`aws ec2 create-subnet --vpc-id ${EC2_VPC_ID} --cidr-block ${EC2_PRIVATE_SUBNET_CIDR} --availability-zone ${AWS_DEFAULT_REGION}c --tag-specifications ${STRING_EC2_PRIVATE_SUBNET_TAG}`
ISSUCCESS=$?
# check result
if [ $ISSUCCESS -ne 0 ]; then
    echo "Failed to create private subnet."
    exit 1
fi

# ##############################################
# get subnet information
# ##############################################
# get public subnet id
EC2_PUBLIC_SUBNET_ID=`echo ${RET} | jq -r '.Subnet.SubnetId'`
# get public subnet state
EC2_PUBLIC_SUBNET_STATE=`echo ${RET} | jq -r '.Subnet.State'`
# get public subnet cidr block
EC2_PUBLIC_SUBNET_CIDR_BLOCK=`echo ${RET} | jq -r '.Subnet.CidrBlock'`

# get private subnet id
EC2_PRIVATE_SUBNET_ID=`echo ${RET} | jq -r '.Subnet.SubnetId'`
# get private subnet state
EC2_PRIVATE_SUBNET_STATE=`echo ${RET} | jq -r '.Subnet.State'`
# get private subnet cidr block
EC2_PRIVATE_SUBNET_CIDR_BLOCK=`echo ${RET} | jq -r '.Subnet.CidrBlock'`

# ##############################################
# output
# ##############################################
echo "*** Public Subnet Information ***"
echo "Public Subnet Name: ${EC2_PUBLIC_SUBNET_NAME}"
echo "Public Subnet ID: ${EC2_PUBLIC_SUBNET_ID}"
echo "Public Subnet State: ${EC2_PUBLIC_SUBNET_STATE}"
echo "Public Subnet CIDR Block: ${EC2_PUBLIC_SUBNET_CIDR_BLOCK}"
echo "***********************"

echo "*** Private Subnet Information ***"
echo "Private Subnet Name: ${EC2_PRIVATE_SUBNET_NAME}"
echo "Private Subnet ID: ${EC2_PRIVATE_SUBNET_ID}"
echo "Private Subnet State: ${EC2_PRIVATE_SUBNET_STATE}"
echo "Private Subnet CIDR Block: ${EC2_PRIVATE_SUBNET_CIDR_BLOCK}"
echo "***********************"

# ##############################################
# End of File
# ##############################################
