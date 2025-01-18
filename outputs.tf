output "task_info" {
  value = [for task in aws_ecs_task_definition.task : {"task_arn" : task.arn_without_revision, "task_id" : task.id}]
}
