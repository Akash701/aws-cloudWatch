resource "aws_cloudwatch_log_group" "app_log_group" {
  name              = var.log_group_name
  retention_in_days = var.retaination_in_days
}

# resource "aws_cloudwatch_log_event" "test_error_event" {
#   log_group_name  = var.log_group_name
#   log_stream_name = var.log_stream_name
#   # Terraform doesn’t have a native log_event resource, so we use the put_log_events via null_resource
# }
resource "aws_cloudwatch_log_stream" "app_log_stream" {
  name           = "test-stream"
  log_group_name = var.log_group_name
}

resource "aws_cloudwatch_log_metric_filter" "error_filter" {
  name           = "ErrorFilter"
  log_group_name = aws_cloudwatch_log_group.app_log_group.name
  pattern        = "ERROR"

  metric_transformation {
    name = "ErrorCount"
    namespace = "MyApp"
    value = "1"
  }
}
// Alarm to monitor the error count too may errors 

# resource "aws_cloudwatch_metric_alarm" "error_alarm" {
#   alarm_name          = "HighErrorRateAlarm"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 1
#   metric_name         = aws_cloudwatch_log_metric_filter.error_filter.metric_transformation[0].name
#   namespace           ="MyApp"
#   period = 60
#   statistic = "Sum"
#   threshold = 5
#   alarm_description = "Alarm when error count exceeds 5 in a minute"
  
# }

resource "aws_iam_role" "budget_alerts_role" {
  name = "budget-alerts-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "budgets.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}


// SNS Topic for sending alerts
resource "aws_sns_topic" "alerts" {
  name = "myapp-alerts"
}

//SNS Subscription to send email alerts
resource "aws_iam_policy" "budget_alerts_policy" {
  name        = "budget-alerts-policy"
  description = "Allow AWS Budgets to publish to SNS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "budget_alerts_attach" {
  role       = aws_iam_role.budget_alerts_role.name
  policy_arn = aws_iam_policy.budget_alerts_policy.arn
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.endpoint_email
}

resource "aws_sns_topic_subscription" "number_sub" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "sms"
  endpoint  = var.endpoint_number
}


 //CloudWatch Log Metric Filter (looks for "ERROR" in /myapp/logs)
resource "aws_cloudwatch_metric_alarm" "error_alarm" {
  alarm_name = "myapp_error_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 1
  metric_name = aws_cloudwatch_log_metric_filter.error_filter.metric_transformation[0].name
  namespace = aws_cloudwatch_log_metric_filter.error_filter.metric_transformation[0].namespace
  period = 60
  statistic = "Sum"
  threshold = 1

  alarm_description = "Alarm if Error appears in logs"
  alarm_actions = [aws_sns_topic.alerts.arn] 
  
}

resource "aws_budgets_budget" "monthly_cost" {
  name         = "monthly-cost-budget"
  budget_type  = "COST"
  limit_amount = "5"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # cost_filters = {
  #   name = "Service"
  #   values = ["AmazonEC2"]
  # }
notification {
  comparison_operator = "GREATER_THAN"
  threshold = 80
  threshold_type = "PERCENTAGE"
  notification_type = "FORECASTED"
  
}
# notification {
#   comparison_operator = "GREATER_THAN"
#   threshold = 100
#   threshold_type = "PERCENTAGE"
#   notification_type = "ACTUAL"
#   subscriber {
#     address = var.endpoint_number
#     subscription_type = "SMS"
#   }
# }
}

# Budget Action: when actual > 100%
resource "aws_budgets_budget_action" "budget_alert_action" {
  budget_name        = aws_budgets_budget.monthly_cost.name
  action_type        = "APPLY_IAM_POLICY"
  execution_role_arn = aws_iam_role.budget_alerts_role.arn
  notification_type  = "FORECASTED"
  approval_model = "AUTOMATIC"

  action_threshold {
    action_threshold_type = "PERCENTAGE"
    action_threshold_value = 80
  }

  definition {
    iam_action_definition {
      policy_arn = aws_iam_policy.budget_alerts_policy.arn
      roles      = [aws_iam_role.budget_alerts_role.name]
      groups     = []
      users      = []
    }
  }

   subscriber {
    subscription_type = "EMAIL"
    address          = var.endpoint_email
  }

  # subscriber {
  #   subscription_type = "SMS"
  #   address           = aws_sns_topic.alerts.arn
  # }
  }
resource "null_resource" "push_test_error" {
  depends_on = [aws_cloudwatch_log_stream.app_log_stream]

  provisioner "local-exec" {
    command = <<EOT
      aws logs put-log-events \
        --log-group-name "${var.log_group_name}" \
        --log-stream-name "${aws_cloudwatch_log_stream.app_log_stream.name}" \
        --log-events '[{"timestamp":'$(date +%s000)',"message":"ERROR Test log event from Terraform"}]'
    EOT
  }
}
