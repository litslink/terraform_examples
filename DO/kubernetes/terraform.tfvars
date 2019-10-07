# rename this file removing .example
do_token = "DigitalOcean API Token"
do_kubernetes_slug = "1.15.3-do.3"   # Get actual version: https://slugs.do-api.dev/
do_node_pool_staging_droplet_slug = "s-1vcpu-2gb"
do_node_pool_production_droplet_slug = "s-1vcpu-2gb" # production CPU Optimized: 4GB/2vCPU/40$ "c-2"
gitlab_runner_token = "GitLab Runner token from GitLab project" # Get GitLab CI runner token ( *Settings* -> *CI/CD* -> *Runners* -> *Set up a specific Runner manually* )
grafana_admin_pass = "Provide password for default admin account for grafana interface"
slack_api_url = "Provide webhook URL for Slack notifications"
slack_channel_name = "Provide Slack channel name"