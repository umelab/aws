#!/bin/bash

########################################################
#                                                       
# Amazon EFSを新規作成します
# 起動方法:
#  $ ./create_efs.sh <efs-name>
#
# 2023/08/17 e.umeda
#
#########################################################
# 
# パフォーマンスモード
PER_MODE=generalPurpose
# スループットモード burting/provisioned/elastic
THROUGHPUT=elastic
# アベイラビリティーゾーン
AVAIL_ZONE=ap-northeast-1a
# リージョン
REGION=ap-northeast-1a
# サブネットID
SUBNET_ID=("subnet-0040e739ec5eb0a61" "subnet-07285e4ab5737af5f")
# セキュリティグループID
SECURITYGR_ID=sg-0acd0b5b1bfaabebd

# ##############################################
# check args
# ##############################################
if [ $# -ne 1 ]; then
    echo "Usage: $0 <vpc-id>"
    exit 1
else 
    EFS_NAME="$1"
fi  

echo ----- create efs -----
# EFS作成
FILESYS_ID=$(aws efs create-file-system \
        --performance-mod "${PER_MODE}" \
        --encrypted \
        --backup \
        --throughput-mode "${THROUGHPUT}" \
        --output text \
        --query "FileSystemId" \
        --tags "Key=Name,Value=${EFS_NAME}"
        )

ISSUCCESS=$?
if [ "$ISSUCCESS" -ne 0 ]; then
  echo "failed to create efs";
  exit 1
fi

echo ----- file-system-id -----
echo ${FILESYS_ID}
echo --------------------------

echo ---- waiting for LifeCycleState ----
while true
do
    # describe-file-systemsでEFS作成完了を確認する
    RET=$(aws efs describe-file-systems \
            --file-system-id "${FILESYS_ID}" \
        | jq -r '.FileSystems[0].LifeCycleState' \
        )
    # ループ抜ける
    if [ "$RET" = "available" ]; then
      break;
    fi
    sleep 1
done

echo ----- setup lifecycle configuration -----
# ライフサイクル管理設定
RET=$(aws efs put-lifecycle-configuration \
        --file-system-id "${FILESYS_ID}" \
        --lifecycle-policies "TransitionToIA=AFTER_30_DAYS"
    )
ISSUCCESS=$?
if [ "$ISSUCCESS" -ne 0 ]; then
  echo "failed to setup lifecycle-configuration";
  exit 1
fi

echo ----- create mount target -----
for id in ${SUBNET_ID[@]}; do
    # マウントターゲット作成
    RET=$(aws efs create-mount-target \
            --file-system-id "${FILESYS_ID}" \
            --subnet-id "${id}" \
            --security-group "${SECURITYGR_ID}" \
        )
    ISSUCCESS=$?
    if [ "$ISSUCCESS" -ne 0 ]; then
    echo "failed to create mount target";
    exit 1
    fi
done

