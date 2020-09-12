##################################################################################
# VARIABLES    us-east-2   Ohio
##################################################################################

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {}
variable "region" {
  default = "us-east-2"
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

##################################################################################
# DATA
##################################################################################

#data "aws_ami" "aws-linux" {
#  most_recent = true
#  owners      = ["amazon"]

#  filter {
#    name   = "name"
#    values = ["amzn-ami-hvm*"]
#  }

#  filter {
#    name   = "root-device-type"
#    values = ["ebs"]
#  }

#  filter {
#    name   = "virtualization-type"
#    values = ["hvm"]
#  }
#}


##################################################################################
# RESOURCES
##################################################################################

#This uses the default VPC.  It WILL NOT delete it on destroy.
resource "aws_default_vpc" "default" {

}

resource "aws_sqs_queue" "sqs_queue" {
  name = "sqs_queue"
}

#FIFO queue creation
#resource "aws_sqs_queue" "terraform_queue" {
#  name                        = "terraform-example-queue.fifo"
#  fifo_queue                  = true
#  content_based_deduplication = true
#}

resource "aws_sns_topic" "sns_topic" {
  name = "sns_topic"
}

resource "aws_sqs_queue_policy" "sqs_queue_policy" {
  queue_url = aws_sqs_queue.sqs_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.sqs_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.sns_topic.arn}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_user" "sqs_user" {
  name = "sqs_user"
  path = "/system/"

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_access_key" "sqs_user_key" {
  user = aws_iam_user.sqs_user.name
}

resource "aws_iam_user_policy" "sqs_user_policy" {
  name = "test"
  user = aws_iam_user.sqs_user.name
  
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage*",
        "sqs:PurgeQueue",
        "sqs:ChangeMessageVisibility*"
      ],
      "Resource": "${aws_sqs_queue.sqs_queue.arn}"
    }
  ]
}
EOF

}


##################################################################################
# OUTPUT
##################################################################################

output "sqs_id" {
  value       = aws_sqs_queue.sqs_queue.id
  description = "The URL for the created Amazon SQS queue."
}

output "sns_id" {
  value       = aws_sns_topic.sns_topic.id
  description = "The URL for the created Amazon SNS topic."
}

output "iam_user_id" {
  value       = aws_iam_user.sqs_user.id
  description = "The URL for the created Amazon IAM user."
}

output "iam_access_key_id" {
  value       = aws_iam_access_key.sqs_user_key.id
  description = "The URL for the created Amazon IAM access key."
}


