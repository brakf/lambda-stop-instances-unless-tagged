data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda_function.py"
  output_path = "temp_lambda_function.zip"
}

resource "aws_iam_role" "iam_for_lambda" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow",
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "ec2_stop_instances" {
  statement {
    actions = [
      "ec2:Describe*",
      "ec2:StopInstances",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "ec2_stop_instances" {
  description = "Allows stopping EC2 instances for lambda function"
  policy      = data.aws_iam_policy_document.ec2_stop_instances.json
}

resource "aws_iam_role_policy_attachment" "ec2_stop_instances_policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.ec2_stop_instances.arn
}


resource "aws_lambda_function" "lambda" {
  function_name = "ec2_stop_instances_unless_tagged"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.iam_for_lambda.arn
  filename      = data.archive_file.lambda_zip.output_path
  timeout       = 60

  depends_on = [
    aws_iam_role_policy_attachment.lambda_exec_policy_attachment,
  ]

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

resource "aws_cloudwatch_event_rule" "daily_stop_instances_unless_tagged" {
  name                = "DailyStopInstancesUnlessTagged"
  schedule_expression = "cron(0 ${var.stop_hour} * * ? *)"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_stop_instances_unless_tagged.arn
}

resource "aws_cloudwatch_event_target" "daily_stop_instances_unless_tagged" {
  rule      = aws_cloudwatch_event_rule.daily_stop_instances_unless_tagged.name
  target_id = "LambdaFunction"
  arn       = aws_lambda_function.lambda.arn
}
