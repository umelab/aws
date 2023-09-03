#!/bin/bash

########################################################
#                                                       
# Amazon EFSを削除します
# 起動方法:
#  $ ./delete_efs.sh <efs-name>
#
# 2023/08/17 e.umeda
#
#########################################################

# ##############################################
# check args
# ##############################################
if [ $# -ne 1 ]; then
    echo "Usage: $0 <vpc-id>"
    exit 1
else 
    EFS_NAME=\"$1\"
fi  

# FileSystemId検索
FILESYS_ID=$(aws efs describe-file-systems \
        | jq -r '.FileSystems[] | select(.Name =='"${EFS_NAME}"') | .FileSystemId')

ISSUCCESS=$?
# aws cli failed
if [ "$ISSUCCESS" -ne 0 ]; then
  echo "failed to execute describe-file-systems";
  exit 1
fi

# unable to find efs
if [ "$FILESYS_ID" = "" ]; then
  echo "unable to find existed efs";
  exit 1
fi

# EFS削除
DEL_EFS_CMD=$(aws efs delete-file-system \
                --file-system-id "${FILESYS_ID}" \
            )

