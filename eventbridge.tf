# EventBridge 규칙 - 매일 자정 (UTC) 실행
resource "aws_cloudwatch_event_rule" "midnight_schedule" {
  name                = "campushub-midnight-schedule"
  description         = "매일 자정에 Lambda 함수 실행"
  schedule_expression = "cron(0 15 * * ? *)"  # UTC 15:00 = KST 자정 (00:00)

  tags = {
    Name    = "campushub-midnight-schedule"
    Project = "campus-hub"
  }
}

# EventBridge 규칙과 Lambda 함수 연결
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.midnight_schedule.name
  target_id = "LambdaTarget"
  arn       = aws_lambda_function.update-classdays.arn
}

# Lambda 함수가 EventBridge에서 호출될 수 있도록 권한 부여
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update-classdays.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.midnight_schedule.arn
}
