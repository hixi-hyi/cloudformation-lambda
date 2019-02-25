#!/bin/bash
if [ -z "$1" ]; then
  echo "usage: $0 \${function}"
  exit 1
fi
function=$1
bucket=$(aws cloudformation list-exports --query "Exports[?Name==\`cfn-lambda-s3:BucketName\`].Value" --output "text")
key=function/${function}.zip

(cd function/${function}/src > /dev/null && zip -q -r ../../${function}.zip ./*)

version=$(script/deploy-if-file-updated.sh $bucket $key)

layers=$(echo "LayerVersionCfnprovider=$(aws s3api head-object --bucket cfn-lambda-s3-bucket-e0dkjneurcdu --key layer/cfnprovider.zip --query 'VersionId' --output 'text')")

aws cloudformation deploy --stack-name cfn-lambda-${function} --template-file function/${function}/deploy.yaml --parameter-overrides LambdaBucket=${bucket} LambdaKey=function/${function}.zip LambdaVersion=${version} ${layers} --capabilities CAPABILITY_IAM
