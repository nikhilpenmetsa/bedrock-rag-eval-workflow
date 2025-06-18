param (
    [Parameter(Mandatory=$true)]
    [string]$S3_BUCKET_NAME
)

# Configuration
$STACK_NAME = "bedrock-rag-evaluation-framework"
$TEMPLATE_FILE = "..\evaluation_framework\template.yaml"
$REGION = "us-west-2"

# Validate that the S3 bucket exists
Write-Host "Validating S3 bucket exists..."
try {
    $bucketExists = aws s3api head-bucket --bucket $S3_BUCKET_NAME 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "S3 bucket '$S3_BUCKET_NAME' does not exist or you don't have access to it."
        exit 1
    }
    Write-Host "S3 bucket '$S3_BUCKET_NAME' exists and is accessible."
} catch {
    Write-Error "Error checking S3 bucket: $_"
    exit 1
}

# Upload mini_wiki.jsonl to S3
Write-Host "Uploading evaluation dataset to S3..."
aws s3 cp ..\dataset\mini_wiki.jsonl s3://$S3_BUCKET_NAME/ground_truth/mini_wiki.jsonl

# Deploy CloudFormation stack
Write-Host "Deploying CloudFormation stack..."
aws cloudformation deploy `
  --template-file $TEMPLATE_FILE `
  --stack-name $STACK_NAME `
  --parameter-overrides `
    S3BucketName=$S3_BUCKET_NAME `
    EvaluationSchedule="rate(1 day)" `
  --capabilities CAPABILITY_IAM `
  --region $REGION

Write-Host "Deployment completed successfully!"
Write-Host "S3 Bucket: $S3_BUCKET_NAME"
Write-Host "Stack Name: $STACK_NAME"
Write-Host "Region: $REGION"