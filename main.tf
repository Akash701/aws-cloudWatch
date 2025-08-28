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

// SNS Topic for sending alerts
resource "aws_sns_topic" "alerts" {
  name = "myapp-alerts"
}

//SNS Subscription to send email alerts

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "akashjnair701@gmail.com"
}

resource "aws_sns_topic_subscription" "number_sub" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "sms"
  endpoint  = "+918888888888"
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
