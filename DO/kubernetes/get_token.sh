#!/bin/bash

# Exit if any of the intermediate steps fail
set -e
# Get token to variable
GITLAB_TOKEN=$(kubectl get secret --kubeconfig=.kubeconfig.yaml $(kubectl  --kubeconfig=.kubeconfig.yaml -n kube-system get secret | grep gitlab-admin | awk '{print $1}') -o jsonpath="{['data']['token']}" -n kube-system | base64 --decode)
# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg token "$GITLAB_TOKEN" '{"token":$token}'