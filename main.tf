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


resource "aws_iam_role" "lambda_role" {
name   = "lambda_role_for_creating_ami_images"
assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}



resource "aws_iam_policy" "lambda_iam_policy" {
 
 name         = "aws_iam_policy_for_terraform_aws_lambda_role"
 description  = "AWS IAM Policy for managing aws lambda role"
 policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [

       "ec2:*",
       "logs:*"
    
     ],
     "Resource": "*",
     "Effect": "Allow"
   }
 ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
 role        =  aws_iam_role.lambda_role.name
 policy_arn  = aws_iam_policy.lambda_iam_policy.arn
}




data "archive_file" "zip_lambda_handler" {  
  type = "zip"  
  source_file = "${path.module}/lambda_handler.py" 
  output_path = "handler.zip"
}






resource "aws_lambda_function" "lambda_handler" {
        function_name = "create_wp_ami_backup"
        filename      = "handler.zip"
        source_code_hash = data.archive_file.zip_lambda_handler.output_base64sha256
        role          = aws_iam_role.lambda_role.arn
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