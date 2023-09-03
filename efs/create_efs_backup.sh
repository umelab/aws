#!/bin/bash

########################################################
#                                                       
# Amazon EFSをAWS Backupからリストアして新規作成します
# 起動方法:
#  $ ./create_efs_backup.sh <efs-name>
#
# 2023/08/25 e.umeda
#
#########################################################
# 
# Account ID
ACCOUNT_ID=000000000000000
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
# リカバリポイント
RECOVERY_POINT_ARN=arn:aws:backup:ap-northeast-1:${ACCOUNT_ID}:recovery-point:c2b01728-815b-49eb-b6e9-383406bc779d
# メタデータファイル
META_DATA_FILE=metadata.json
# リストア用ロール
RESTORE_ROLE=arn:aws:iam::${ACCOUNT_ID}:role/test-umeda-aws-backup
# 環境名
DST_ENV_NAME=cokasrg-ume-test
#####################################################################
echo ---- create ${META_DATA_FILE} ----
d=\$(date +%Y%m%d%H%M%S)
cat > ${META_DATA_FILE} << EOF
{
    "file-system-id": "fs-0471defa8c189cb60",
    "Encrypted": "true",
    "KmsKeyId": "21b67897-8cde-43ef-b3fc-c844dfaa0223",
    "PerformanceMode": "generalPurpose",
    "newFileSystem": "true",
    "CreationToken": "creation token ${d}"
}
EOF

# バックアップから新EFSをリストア
echo ---- start restore job ----
RESTORE_JOB_ID=$(aws backup start-restore-job \
        --recovery-point-arn "${RECOVERY_POINT_ARN}" \
        --metadata file://"${META_DATA_FILE}" \
        --iam-role-arn "${RESTORE_ROLE}" \
        | jq -r '.RestoreJobId'
    )
echo "RestoreJobId:"${RESTORE_JOB_ID}

# リストア完了まで待つ
echo ---- polling ----
while true
do
    RET=$(aws backup describe-restore-job \
            --restore-job-id "${RESTORE_JOB_ID}" 
        )
    STATUS=$(echo ${RET} | jq -r '.Status')

    if [ "${STATUS}" = "COMPLETED" ]; then
        RESOURCE_ARN=$(echo ${RET} | jq -r '.CreatedResourceArn')
        break;
    fi
    sleep 1
    echo ---- wait for restore ----
done

echo "Resource Arn:"${RESOURCE_ARN}

# FileSystemId取得
FILE_SYS_ID=$(echo "${RESOURCE_ARN}" | sed -e 's/^arn:aws:[a-z\-]*:[a-z0-9\-]*:[0-9]*:file-system\///')
echo "FILE_SYS_ID:"${FILE_SYS_ID}

# EFSに環境名のタグを作成する
echo ---- create tag resource ----
RET=$(aws efs tag-resource \
        --resource-id "${FILE_SYS_ID}" \
        --tags "Key=Name,Value=${DST_ENV_NAME}"
    )

RET=$(aws efs describe-file-systems \
        --file-system-id "${FILE_SYS_ID}" \
        | jq -r '.FileSystems[0].LifeCycleState' 
    )
echo "LifeCycleState:"${RET}

# ライフサイクル管理設定
echo ---- setup lifecycle configuration ----
RET=$(aws efs put-lifecycle-configuration \
        --file-system-id "${FILE_SYS_ID}" \
        --lifecycle-policies "TransitionToIA=AFTER_30_DAYS"
    )

# マウントターゲット作成
echo ---- create mount target ----
for id in ${SUBNET_ID[@]}; do
    # マウントターゲット作成
    RET=$(aws efs create-mount-target \
            --file-system-id "${FILE_SYS_ID}" \
            --subnet-id "${id}" \
            --security-group "${SECURITYGR_ID}" \
        )
    ISSUCCESS=$?
    if [ "$ISSUCCESS" -ne 0 ]; then
    echo "failed to create mount target";
    exit 1
    fi
done

# マウントターゲットの準備完了まで待つ
echo ----- waiting for available -----
while true
do
    F_IDS=$(aws efs describe-mount-targets \
            --file-system-id "${FILE_SYS_ID}" \
            | jq -r '.MountTargets[] | select(.LifeCycleState=="available") | .FileSystemId'
        )
    if [ "${F_IDS[0]}" = "${FILE_SYS_ID}" ]; then
        echo ---- ready for mount target ----
        break;
    fi
    sleep 1
done
echo ----- finish -----

