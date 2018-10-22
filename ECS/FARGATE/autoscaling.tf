resource "aws_cloudwatch_metric_alarm" "cpu_utilization_high" {
  alarm_name          = "${var.env}-${var.project_name}-CPU-Utilization-High-${var.ecs_as_cpu_high_threshold_per}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "${var.ecs_as_cpu_high_threshold_per}"

  dimensions {
    ClusterName = "${aws_ecs_cluster.ecs_cluster.name}"
    ServiceName = "${aws_ecs_service.ecs_service.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.app_up.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_low" {
  alarm_name          = "${var.env}-${var.project_name}-CPU-Utilization-Low-${var.ecs_as_cpu_low_threshold_per}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "${var.ecs_as_cpu_low_threshold_per}"

  dimensions {
    ClusterName = "${aws_ecs_cluster.ecs_cluster.name}"
    ServiceName = "${aws_ecs_service.ecs_service.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.app_down.arn}"]
}

resource "aws_appautoscaling_policy" "app_up" {
  name               = "app-scale-up"
  service_namespace  = "${aws_appautoscaling_target.ecs_scale_target.service_namespace}"
  resource_id        = "${aws_appautoscaling_target.ecs_scale_target.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.ecs_scale_target.scalable_dimension}"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "app_down" {
  name               = "app-scale-down"
  service_namespace  = "${aws_appautoscaling_target.ecs_scale_target.service_namespace}"
  resource_id        = "${aws_appautoscaling_target.ecs_scale_target.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.ecs_scale_target.scalable_dimension}"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}