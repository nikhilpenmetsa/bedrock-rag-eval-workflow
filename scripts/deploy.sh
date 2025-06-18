#!/bin/bash
set -e

# Check if S3 bucket name is provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <s3-bucket-name>"
    echo "Example: $0 my-bedrock-rag-eval-bucket"
    exit 1
fi

# Configuration
STACK_NAME="bedrock-rag-evaluation-framework"
S3_BUCKET_NAME=$1
TEMPLATE_FILE="../evaluation_framework/template.yaml"
REGION="us-west-2"  # Change to your preferred region

# Validate that the S3 bucket exists
echo "Validating S3 bucket exists..."
if ! aws s3api head-bucket --bucket $S3_BUCKET_NAME 2>/dev/null; then
    echo "Error: S3 bucket '$S3_BUCKET_NAME' does not exist or you don't have access to it."
    echo "Please create the bucket first using: aws s3 mb s3://$S3_BUCKET_NAME"
    exit 1
fi
echo "S3 bucket '$S3_BUCKET_NAME' exists and is accessible."

# Upload mini_wiki.jsonl to S3
echo "Uploading evaluation dataset to S3..."
aws s3 cp ../dataset/mini_wiki.jsonl s3://$S3_BUCKET_NAME/ground_truth/mini_wiki.jsonl

# Deploy CloudFormation stack
echo "Deploying CloudFormation stack..."
aws cloudformation deploy \
  --template-file $TEMPLATE_FILE \
  --stack-name $STACK_NAME \
  --parameter-overrides \
    S3BucketName=$S3_BUCKET_NAME \
    EvaluationSchedule="rate(1 day)" \
  --capabilities CAPABILITY_IAM \
  --region $REGION

echo "Deployment completed successfully!"
echo "S3 Bucket: $S3_BUCKET_NAME"
echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"