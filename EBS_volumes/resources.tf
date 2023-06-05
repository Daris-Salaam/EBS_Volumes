
resource "aws_iam_policy" "lambda-policy" {
  name = "unused-volumes-policy-new"

  policy = jsonencode({
   "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVolumeStatus",
                "sns:ListSubscriptionsByTopic",
                "sns:Publish",
                "sns:GetTopicAttributes",
                "ec2:DescribeVolumes",
                "logs:*",
                "sns:ListSubscriptions",
                "ec2:DescribeVolumeAttribute"
            ],
            "Resource": "*"
        }
    ]
  })
}

resource "aws_iam_role" "lambda-role" {
  name = "unused-volumes-role-new"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "unused-volumes-role"
  }
}

resource "aws_iam_role_policy_attachment" "lambda-ec2-policy-attach" {
  role       = aws_iam_role.lambda-role.name
  policy_arn = aws_iam_policy.lambda-policy.arn
}

resource "aws_sns_topic" "snstopic" {
    name = "unused_volumes_notify"
    display_name = "unused_volumes_notify"
    tags = {
        "Name" = "unused_volumes_notify_alerts"
    }
}

resource "aws_sns_topic_subscription" "snstopicsubcription" {
    topic_arn = aws_sns_topic.snstopic.arn
    protocol = "email"
    endpoint = "daris.salaam@ibm.com"
}

resource "aws_lambda_function" "unused-volumes" {
  filename      = "volumes_unused.zip"
  function_name = "unused_volumes"
  role          = aws_iam_role.lambda-role.arn
  handler       = "volumes_unused.lambda_handler"

  source_code_hash = filebase64sha256("volumes_unused.zip")

  runtime = "python3.7"
  timeout = 63
}

resource "aws_cloudwatch_event_target" "lambda-stop-func" {
  rule      = aws_cloudwatch_event_rule.unused-volumes-notify.name
  target_id = "unused_volumes"
  arn       = aws_lambda_function.unused-volumes.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_unsused_volumes" {
  statement_id  = "AllowExecutionFromCloudWatchUnusedVolumes"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.unused-volumes.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.unused-volumes-notify.arn
}

resource "aws_cloudwatch_event_rule" "unused-volumes-notify" {
  name                = "unused-volumes-notify"
  description         = "Trigger receive notification at 6:54 pm IST "
  schedule_expression = "cron(24 13 ? * THUR *)"        #Scheduled at require intervals
  
}

