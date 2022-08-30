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

data "archive_file" "zip_lambda_handler" {  
  type = "zip"  
  source_file = "${path.module}/lambda_handler.py" 
  output_path = "handler.zip"
}


resource "aws_lambda_function" "lambda_handler" {
        function_name = "create_wp_ami_backup"
        filename      = "handler.zip"
        source_code_hash = data.archive_file.python_lambda_package.output_base64sha256
        role          = aws_iam_role.lambda_role.arn
        runtime       = "python3.6"
        handler       = "lambda_function.lambda_handler"
        timeout       = 10
}

resource "aws_cloudwatch_event_rule" "create_ami_backup" {
    name = "create_ami_backup"
    description = "create_wp_backup"
    schedule_expression = "cron(30 21 * * *)"
}

resource "aws_cloudwatch_event_target" "initiate_backup" {
    target_id = "initiate_backup"
    rule = "${aws_cloudwatch_event_rule.create_ami_backup.name}"
    arn = "${aws_lambda_function.lambda_handler.arn}"
    
}