#!/bin/bash

########################################################
#                                                       
# Amazon Transfer FamilyのSFTPサーバを新規作成します
# 起動方法:
#  $ ./create_sftp.sh <sftp-name>
#
# 2023/08/24 e.umeda
#
#########################################################
SERVER_NAME=test
STORAGE_SYSTEM=EFS
END_POINT_TYPE=PUBLIC
PROVIDER_TYPE=SERVICE_MANAGED
PROTOCOL=SFTP
LOG_GROUP_NAME=test-umeda-log-group
REGION=ap-northeast-1
DEBUG=false
USER_ID=1000
GROUP_ID=1000
USER_NAME=testUser
#ROLE_ARNS=arn:aws:iam::136903743861:role/test-umeda-aws-transfer-family-efs

# 指定されたロググループ存在有無
CNT=$(aws logs describe-log-groups \
        --log-group-name-prefix ${LOG_GROUP_NAME} \
        | jq -r '.logGroups | length'
    )

if [ "$CNT" -gt 0 ]; then
  echo "log group is already existed. pls change log group name."
  exit 1
else
  # ロググループを作成する
  RET=$(aws logs create-log-group \
          --log-group-name ${LOG_GROUP_NAME} 
      )
fi

# Account id取得
ACCOUNT_ID=$(aws sts get-caller-identity \
        | jq -r '.Account'
    )
LOG_DEST="arn:aws:logs:${REGION}:${ACCOUNT_ID}:log-group:${LOG_GROUP_NAME}:*"
ROLE_ARNS=arn:aws:iam::${ACCOUNT_ID}:role/test-umeda-aws-transfer-family-efs

if [ "${DEBUG}" = true ]; then
  echo "Account ID:"${ACCOUNT_ID}
  echo "Log Group Name:"${LOG_GROUP_NAME}
  echo "Region:"${REGION}
  echo "Log Destination:"${LOG_DEST}
fi

# SFTPサーバ作成
SERVER_ID=$(aws transfer create-server \
        --domain "${STORAGE_SYSTEM}" \
        --endpoint-type "${END_POINT_TYPE}" \
        --identity-provider-type "${PROVIDER_TYPE}" \
        --protocols "${PROTOCOL}" \
        --tags "Key=Name,Value=${SERVER_NAME}" \
        --structured-log-destinations "${LOG_DEST}" \
        | jq -r '.ServerId' 
    )

echo ${SERVER_ID}

# ユーザ作成
USER_ID=$(aws transfer create-user \
            --server-id "${SERVER_ID}" \
            --user-name "${USER_NAME}" \
            --home-directory-type "PATH" \
            --home-directory "//${SERVER_ID}" \
            --posix-profile "Uid=${USER_ID},Gid=${GROUP_ID}" \
            --role "${ROLE_ARNS}" \
        )
echo --------------------------------------
echo $RET
echo --------------------------------------