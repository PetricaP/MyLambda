terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.0"
}

provider "aws" {
  region = var.aws_region
}

resource "random_pet" "lambda_bucket_name" {
  prefix = "learn-terraform-functions"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id

  force_destroy = true
}

data "archive_file" "lambda_hello_world" {
  type = "zip"

  source_file  = "${path.module}/../hello_lambda/target/x86_64-unknown-linux-musl/release/bootstrap"
  output_path = "${path.module}/hello_lambda.zip"
}

resource "aws_s3_object" "lambda_hello_world" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "hello_lambda.zip"
  source = data.archive_file.lambda_hello_world.output_path

  etag = filemd5(data.archive_file.lambda_hello_world.output_path)
}

resource "aws_s3_bucket" "my_bucket" {
    bucket = "ppetrica-bucket-2"
}

resource "aws_lambda_function" "hello_world" {
  function_name = "HelloWorld"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_hello_world.key

  runtime = "provided.al2"
  handler = "hello.handler"

  source_code_hash = data.archive_file.lambda_hello_world.output_base64sha256

  role = aws_iam_role.lambda_exec.arn

  environment {
      variables = {
          BUCKET_NAME = aws_s3_bucket.my_bucket.bucket
      }
  }
}

resource "aws_cloudwatch_log_group" "hello_world" {
  name = "/aws/lambda/${aws_lambda_function.hello_world.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "ppetrica_bucket_access" {
  statement {
    actions   = ["s3:*"]
    resources = ["${aws_s3_bucket.my_bucket.arn}/*"]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "s3_policy" {
    name = "S3AccessPolicy"
    description = "Policy to access my s3 bucket"
    policy = data.aws_iam_policy_document.ppetrica_bucket_access.json
}

resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
    role = aws_iam_role.lambda_exec.name
    policy_arn = aws_iam_policy.s3_policy.arn
}
