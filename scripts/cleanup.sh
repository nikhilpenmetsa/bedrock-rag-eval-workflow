#!/bin/bash
set -e

# Check if required parameters are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <stack-name> <s3-bucket-name>"
    echo "Example: $0 bedrock-rag-evaluation-framework my-bedrock-rag-eval-bucket"
    exit 1
fi

STACK_NAME=$1
S3_BUCKET_NAME=$2
REGION="us-west-2"  # Change to your preferred region

# Delete CloudFormation stack
echo "Deleting CloudFormation stack..."
aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION

# Wait for stack deletion to complete
echo "Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME --region $REGION

# Empty and delete S3 bucket if specified
read -p "Do you want to empty and delete the S3 bucket $S3_BUCKET_NAME? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Emptying S3 bucket..."
    aws s3 rm s3://$S3_BUCKET_NAME --recursive
    echo "Deleting S3 bucket..."
    aws s3api delete-bucket --bucket $S3_BUCKET_NAME --region $REGION
fi

echo "Cleanup completed successfully!"