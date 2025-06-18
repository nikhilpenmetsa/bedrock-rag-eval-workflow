# Configuration
$STACK_NAME = "bedrock-rag-evaluation-framework"
$REGION = "us-west-2"

# Get S3 bucket name from stack outputs
Write-Host "Getting S3 bucket name from stack outputs..."
$S3_BUCKET_NAME = (aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='S3BucketName'].OutputValue" --output text --region $REGION)

if ($S3_BUCKET_NAME) {
    # Empty S3 bucket first (required before deletion)
    Write-Host "Emptying S3 bucket $S3_BUCKET_NAME..."
    aws s3 rm s3://$S3_BUCKET_NAME --recursive

    # Delete CloudFormation stack
    Write-Host "Deleting CloudFormation stack $STACK_NAME..."
    aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION

    Write-Host "Waiting for stack deletion to complete..."
    aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME --region $REGION

    # Delete S3 bucket after stack is deleted
    Write-Host "Deleting S3 bucket $S3_BUCKET_NAME..."
    aws s3api delete-bucket --bucket $S3_BUCKET_NAME --region $REGION
}
else {
    # Delete CloudFormation stack
    Write-Host "Deleting CloudFormation stack $STACK_NAME..."
    aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION

    Write-Host "Waiting for stack deletion to complete..."
    aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME --region $REGION
}

Write-Host "Cleanup completed successfully!"