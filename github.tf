resource "github_repository" "repo" {
  name       = var.github_repo
  visibility = var.github_visibility
}

resource "github_repository_webhook" "github_webhook" {
  repository = github_repository.repo.name
  configuration {
    url          = "${aws_api_gateway_deployment.github_webhook_deployment.invoke_url}/${aws_api_gateway_resource.github_webhook.path_part}"
    content_type = "json"
    insecure_ssl = false
  }
  active = var.is_webhook_active
  events = ["push", "pull_request"]
}
