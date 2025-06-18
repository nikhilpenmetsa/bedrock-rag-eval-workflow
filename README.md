# Bedrock RAG Evaluation Framework

This project shows a workflow for evaluating a RAG system using [Amazon Bedrock Evaluations](https://docs.aws.amazon.com/bedrock/latest/userguide/evaluation-kb.html).

## Overview

Evaluation frameworks are essential for maintaining predictable behavior when evolving RAG systems, as even minor changes to prompts, embeddings, or knowledge bases can have cascading effects on response quality and system reliability. Without comprehensive testing across multiple dimensions (accuracy, relevance, latency, and consistency), seemingly beneficial modifications could inadvertently introduce regressions or unexpected behaviors that might only surface in production environments.

In this solution, we use the [rag-mini dataset](https://huggingface.co/datasets/rag-datasets/rag-mini-wikipedia) as the knowledge base for this evaluation framework. A subset of this data is used as ground-truth.

![Evaluation Workflow](https://github.com/nikhilpenmetsa/bedrock-rag-eval-workflow/blob/main/images/stepfunctions_graph.svg)

## Project Structure

```
bedrock-rag-eval/
├── dataset/
│   ├── sample_output/       # Sample evaluation output
│   │   └── output.jsonl     # Example of evaluation results
│   └── mini_wiki.jsonl      # Sample evaluation dataset
├── evaluation_framework/
│   ├── step_function.json   # Step Function definition
│   └── template.yaml        # CloudFormation template with embedded Lambda functions
└── scripts/
    ├── deploy.sh            # Deployment script for Linux/macOS
    ├── deploy.bat           # Deployment script for Windows (calls deploy.ps1)
    ├── deploy.ps1           # PowerShell deployment script
    ├── cleanup.bat          # Cleanup script for Windows
    ├── cleanup.ps1          # PowerShell cleanup script
    ├── cleanup.sh           # Cleanup script for Linux/macOS
    └── README.md            # Instructions for test scripts
```

## How It Works

1. An EventBridge rule triggers the Step Function workflow on a scheduled basis
2. The first Lambda function retrieves configuration from SSM Parameter Store and creates a Bedrock evaluation job
3. The Step Function waits and periodically checks the status of the evaluation job
4. Once complete, another Lambda function processes the results and stores them in DynamoDB
5. The results can be visualized through a frontend application (to be implemented)

## Deployment

### Prerequisites

- AWS CLI installed and configured
- Appropriate AWS bedrock model access (Nova Pro, Claude 3.7 Sonnet used in this repository )
- An S3 bucket for storing evaluation datasets and results
- A Bedrock knowledge base with rag-mini dataset already set up.

### Deployment Steps

1. Create an S3 bucket to store your evaluation datasets and results:
```
aws s3 mb s3://your-s3-bucket-name
```

2. Upload the evaluation dataset to the S3 bucket:
```
aws s3 cp dataset/mini_wiki.jsonl s3://your-s3-bucket-name/ground_truth/mini_wiki.jsonl
```

3. Deploy the framework:

For Windows:
```
cd scripts
deploy.bat -S3_BUCKET_NAME your-s3-bucket-name
```

For Linux/macOS:
```
cd scripts
chmod +x deploy.sh
./deploy.sh your-s3-bucket-name
```

## Configuration

The following parameters are stored in SSM Parameter Store and are automatically created during deployment:

- `/bedrock-rag-eval/application_name`: Name of the application being evaluated
- `/bedrock-rag-eval/kb_id`: Knowledge Base ID for RAG evaluation
- `/bedrock-rag-eval/evaluator_model_id`: Model ID for the evaluator (default: Nova Pro)
- `/bedrock-rag-eval/generator_model_id`: Model ID for the generator (default: Claude 3.7 Sonnet)

Update these parameters in the AWS Console or using the AWS CLI after deployment.

## Dataset Information

The evaluation uses a sample dataset (`mini_wiki.jsonl`) derived from the [rag-mini-wikipedia dataset](https://huggingface.co/datasets/rag-datasets/rag-mini-wikipedia). This dataset contains factual information that serves as both the knowledge base content and the ground truth for evaluation queries.

### Evaluation Dataset Format

The evaluation dataset follows this format:

```json
{
  "conversationTurns": [
    {
      "prompt": {
        "content": [
          {
            "text": "Where was Woodrow Wilson born?"
          }
        ]
      },
      "referenceResponses": [
        {
          "content": [
            {
              "text": "Woodrow Wilson was born in Staunton, Virginia"
            }
          ]
        }
      ]
    }
  ]
}
```

You can replace this with your own evaluation dataset following the same format.

## Evaluation Metrics

The framework evaluates RAG responses using the following built-in metrics:

1. **Correctness**: Measures if the response contains factually correct information
2. **Completeness**: Evaluates if the response includes all necessary information
3. **Helpfulness**: Assesses how useful and relevant the response is to the query
4. **Logical Coherence**: Checks if the response is logically consistent
5. **Faithfulness**: Determines if the response accurately represents information from the retrieved passages

## Sample Output

The evaluation results are stored in both S3 and DynamoDB. Here's an example of the output format:

```json
{
  "conversationTurns": [{
    "inputRecord": {
      "prompt": {"content": [{"text": "Where was Woodrow Wilson born?"}]},
      "referenceResponses": [{"content": [{"text": "Woodrow Wilson was born in Staunton, Virginia"}]}]
    },
    "output": {
      "modelIdentifier": "arn:aws:bedrock:us-west-2:1234543323:inference-profile/us.anthropic.claude-3-7-sonnet-20250219-v1:0",
      "knowledgeBaseIdentifier": "3UWWAYOA4C",
      "text": "Thomas Woodrow Wilson was born in Staunton, Virginia in 1856. He was the third of four children born to Reverend Dr. Joseph Wilson and Janet Woodrow.",
      "retrievedPassages": {...},
      "citations": [...]
    },
    "results": [
      {"metricName": "Builtin.Correctness", "result": 1.0},
      {"metricName": "Builtin.Completeness", "result": 1.0},
      {"metricName": "Builtin.Helpfulness", "result": 0.8333},
      {"metricName": "Builtin.LogicalCoherence", "result": 1.0},
      {"metricName": "Builtin.Faithfulness", "result": 1.0}
    ]
  }]
}
```

## Cleanup

To remove all resources created by this framework:

For Windows:
```
cd scripts
cleanup.bat -StackName bedrock-rag-evaluation-framework -S3BucketName your-s3-bucket-name
```

For Linux/macOS:
```
cd scripts
chmod +x cleanup.sh
./cleanup.sh bedrock-rag-evaluation-framework your-s3-bucket-name
```

The cleanup scripts will delete the CloudFormation stack and optionally empty and delete the S3 bucket.

## Future Enhancements

- Frontend application for visualizing evaluation results
- Support for multiple evaluation datasets
- Comparison of evaluation results over time
- Notifications for evaluation completion or failures
- Custom evaluation metrics
- Integration with CI/CD pipelines for automated testing