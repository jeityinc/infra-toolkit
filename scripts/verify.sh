#!/usr/bin/env bash
set -euo pipefail

required_commands=(
  aws
  bash
  curl
  git
  jq
  node
  npm
  openssl
  python3
  ruby
  terraform
  tflint
  unzip
)

for command_name in "${required_commands[@]}"; do
  command -v "${command_name}" >/dev/null
done

terraform version -json \
  | jq --exit-status '.terraform_version == "1.16.5"' >/dev/null

node --version | grep --quiet '^v22\.'
tflint --version | grep --fixed-strings 'TFLint version 0.59.1' >/dev/null
aws --version 2>&1 | grep --fixed-strings 'aws-cli/2.37.3' >/dev/null
openssl version >/dev/null

test -d "${TF_PLUGIN_CACHE_DIR:-/opt/terraform/plugin-cache}"
test -n "$(find "${TF_PLUGIN_CACHE_DIR:-/opt/terraform/plugin-cache}" -type f -o -type l 2>/dev/null | head -n 1)"

echo "infra-toolkit verification passed"
