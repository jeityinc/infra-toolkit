FROM node:22.20.0-bookworm-slim

ARG TARGETARCH=amd64
ARG TERRAFORM_VERSION=1.16.5
ARG TERRAFORM_LINUX_AMD64_SHA256=2bc2fcfff033265c9e02ca0351f01794eb122f62a9b2a49a3294b9e49eaab5e4
ARG TFLINT_VERSION=0.59.1
ARG AWS_CLI_VERSION=2.37.3

ENV DEBIAN_FRONTEND=noninteractive \
    TF_IN_AUTOMATION=true \
    TF_INPUT=false \
    CHECKPOINT_DISABLE=1 \
    TF_PLUGIN_CACHE_DIR=/opt/terraform/plugin-cache

RUN set -eux; \
    test "${TARGETARCH}" = "amd64"; \
    apt-get update; \
    apt-get install --no-install-recommends -y \
      bash \
      ca-certificates \
      curl \
      git \
      jq \
      python3 \
      ruby \
      unzip; \
    rm -rf /var/lib/apt/lists/*

# Terraform
RUN set -eux; \
    archive="terraform_${TERRAFORM_VERSION}_linux_amd64.zip"; \
    curl --fail --location --silent --show-error \
      "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${archive}" \
      --output "/tmp/${archive}"; \
    printf '%s  %s\n' "${TERRAFORM_LINUX_AMD64_SHA256}" "/tmp/${archive}" \
      | sha256sum --check --strict -; \
    unzip -q "/tmp/${archive}" -d /usr/local/bin; \
    rm -f "/tmp/${archive}"; \
    terraform version

# TFLint
RUN set -eux; \
    archive="tflint_linux_amd64.zip"; \
    curl --fail --location --silent --show-error \
      "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/${archive}" \
      --output "/tmp/${archive}"; \
    curl --fail --location --silent --show-error \
      "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/checksums.txt" \
      --output /tmp/tflint-checksums.txt; \
    cd /tmp; \
    grep "  ${archive}$" tflint-checksums.txt | sha256sum --check --strict -; \
    unzip -q "${archive}" -d /usr/local/bin; \
    rm -f "${archive}" tflint-checksums.txt; \
    tflint --version

# AWS CLI v2
RUN set -eux; \
    curl --fail --location --silent --show-error \
      "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" \
      --output /tmp/awscliv2.zip; \
    unzip -q /tmp/awscliv2.zip -d /tmp; \
    /tmp/aws/install; \
    rm -rf /tmp/aws /tmp/awscliv2.zip; \
    aws --version

# Pre-warm the TFLint AWS ruleset cache used by jeity-infra.
COPY tflint-cache/.tflint.hcl /tmp/tflint-cache/.tflint.hcl
RUN set -eux; \
    tflint --init --config /tmp/tflint-cache/.tflint.hcl; \
    rm -rf /tmp/tflint-cache

# Pre-warm Terraform provider packages used by jeity-infra.
COPY terraform-cache/providers.tf /tmp/terraform-cache/providers.tf
RUN set -eux; \
    mkdir -p "${TF_PLUGIN_CACHE_DIR}"; \
    terraform -chdir=/tmp/terraform-cache init -backend=false -input=false; \
    rm -rf /tmp/terraform-cache

COPY scripts/verify.sh /usr/local/bin/infra-toolkit-verify
RUN chmod 0755 /usr/local/bin/infra-toolkit-verify \
    && infra-toolkit-verify

WORKDIR /workspace
