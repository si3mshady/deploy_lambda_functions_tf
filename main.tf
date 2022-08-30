terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #   version = "3.26.0"
    }

  }



}

provider "aws" {
  region = "us-east-1"
}


terraform {
  backend "s3" {
    bucket = "tf-state-for-si3mshady"
    key    = "tfstate"
    region = "us-east-1"
  }
}




data "aws_iam_policy_document" "lambda_assume_role_policy" {

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:*"
    ]

    resources = ["*"]

  }

  statement {
    effect = "Allow"

    actions = ["lambda:InvokeFunction"]

    resources = ["*"]
  }

}


data "archive_file" "zip_lambda_handler" {  
  type = "zip"  
  source_file = "${path.module}/lambda_handler.py" 
  output_path = "handler.zip"
}


resource "aws_iam_role" "lambda-iam-role" {  
  name = "lambda-iam-role"  
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}


resource "aws_lambda_function" "lambda_handler" {
        function_name = "create_wp_ami_backup"
        filename      = "handler.zip"
        source_code_hash = data.archive_file.zip_lambda_handler.output_base64sha256
        role          = aws_iam_role.lambda-iam-role.arn
        runtime       = "python3.9"
        handler       = "lambda_handler.lambda_handler"
        timeout       = 10
}

resource "aws_cloudwatch_event_rule" "create_ami_backup" {
    name = "create_ami_backup"
    description = "create_wp_backup"
    schedule_expression = "cron(0/30 * ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "initiate_backup" {
    target_id = "initiate_backup"
    rule = "${aws_cloudwatch_event_rule.create_ami_backup.name}"
    arn = "${aws_lambda_function.lambda_handler.arn}"
    
}


# https://docs.aws.amazon.com/lambda/latest/dg/services-cloudwatchevents-expressions.html