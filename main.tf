terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  version = ">= 2.11"
  region  = var.region
}

locals {
  lambda_job_name_base       = "${var.project_base_name}-lambda"
  mediaconvert_job_name_base = "${var.project_base_name}-mediaconvert"
}

resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
  numeric = false
}

resource "random_uuid" "lambda_src_hash" {
  keepers = {
    for filename in setunion(
      fileset(path.module, "**.py"),
    ) :
    filename => filemd5("${path.module}/source")
  }
}

data "archive_file" "transformer" {
  type        = "zip"
  source_dir = "${path.module}/mediaconvert_lambda"
  output_path = var.lambda_zip_path
}


#--------------------------------------------------------------------------------
# S3 bucket to upload video files to be transcoded
#--------------------------------------------------------------------------------
resource "aws_s3_bucket" "uploaded" {
  bucket = "${var.input_bucket_name}"
  acl    = "private"
  force_destroy = true
  tags = {
    Project = "${var.project_base_name}"
  }
  lifecycle_rule {
    id      = "uploaded"
    enabled = true
    tags = {
      Project = "${var.project_base_name}"
    }
    expiration {
      days = 1
    }
  }
}
#--------------------------------------------------------------------------------
# S3 bucket for Elastic Transcoder to place transcoded video files.
#--------------------------------------------------------------------------------
resource "aws_s3_bucket" "transcoded" {
  bucket = "${var.output_bucket_name}"
  force_destroy = true
  tags = {
    Project = "${var.project_base_name}"
  }
  lifecycle_rule {
    id      = "transcoded"
    enabled = true
    tags = {
      Project = "${var.project_base_name}"
    }
    transition {
      days          = 1
      storage_class = "GLACIER"
    }
  }
}

resource "aws_lambda_function" "this" {
  filename         = var.lambda_zip_path
  function_name    = "${var.project_base_name}-lambda"
  role             = aws_iam_role.lambda_job.arn
  handler          = "mediaconvert.convert_video"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  runtime          = "python3.8"
  timeout          = 60

  environment {
    variables = {
      REGION                = var.region,
      OUTPUT_BUCKET         = var.output_bucket_name,
      MEDIACONVERT_ROLE_ARN = aws_iam_role.mediaconvert_job.arn,
      MEDIACONVERT_ENDPOINT = var.mediaconvert_endpoint,
    }
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.input_bucket_name}"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.input_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.this.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.bucket_event_prefix
    filter_suffix       = var.bucket_event_suffix
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

