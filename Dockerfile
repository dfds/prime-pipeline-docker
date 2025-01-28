# ========================================
# CREATE UPDATED BASE IMAGE
# ========================================

FROM debian:bookworm-slim AS base

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# ========================================
# GENERAL PREREQUISITES
# ========================================

FROM base AS prereqs

RUN apt-get update \
    && apt-get install -y curl unzip git bash-completion jq ssh sudo gnupg groff gcc vim python3 python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Adding  GitHub public SSH key to known hosts
RUN ssh -T -o "StrictHostKeyChecking no" -o "PubkeyAuthentication no" git@github.com || true

# ========================================
# KAFKA MESSAGE PRODUCER
# ========================================

FROM prereqs

RUN apt-get update \
    && apt-get install -y kafkacat \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ========================================
# COPY SCRIPTS AND FILES
# ========================================

COPY src/permanent/scripts /usr/local/bin

COPY src/temporary /tmp

# ========================================
# AWS CLI https://raw.githubusercontent.com/aws/aws-cli/v2/CHANGELOG.rst
# ========================================

ENV AWS_CLI_VERSION=2.23.7

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -sSLo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-${BUILD_ARCHITECTURE}-${AWS_CLI_VERSION}.zip \
    && curl -sSLo awscliv2.sig https://awscli.amazonaws.com/awscli-exe-linux-${BUILD_ARCHITECTURE}-${AWS_CLI_VERSION}.zip.sig \
    && gpg --import /tmp/files/aws-cli.asc \
    && gpg --verify awscliv2.sig awscliv2.zip \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf ./aws \
    && rm -f awscliv2.zip awscliv2.sig /tmp/files/aws-cli.asc

ENV AWS_PAGER=""

# ========================================
# TERRAFORM - version locked
# ========================================

ENV TERRAFORM_VERSION=1.5.7

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -sSLO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.zip \
    && curl -sSLO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS \
    && curl -sSLO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig \
    && gpg --import /tmp/files/hashicorp.asc \
    && gpg --verify terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig terraform_${TERRAFORM_VERSION}_SHA256SUMS \
    && grep terraform_${TERRAFORM_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS | sha256sum --check \
    && unzip terraform_${TERRAFORM_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.zip \
    && rm -f terraform_${TERRAFORM_VERSION}_* /tmp/files/hashicorp.asc \
    && mv terraform /usr/local/bin/terraform \
    && /usr/local/bin/terraform -install-autocomplete

# ========================================
# OpenTofu https://github.com/opentofu/opentofu/releases
# ========================================

ENV OPENTOFU_VERSION=1.9.0

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -sSLO https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.zip \
    && curl -sSLO https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_SHA256SUMS \
    && grep tofu_${OPENTOFU_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.zip tofu_${OPENTOFU_VERSION}_SHA256SUMS | sha256sum --check \
    && /tmp/scripts/install-tofu.sh \
    && rm -f tofu_${OPENTOFU_VERSION}_* /tmp/scripts/install-tofu.sh


# ========================================
# TERRAGRUNT https://github.com/gruntwork-io/terragrunt/releases
# ========================================

ENV TERRAGRUNT_VERSION=0.72.5

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -sSLO https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_${BUILD_ARCHITECTURE_ARCH} \
    && curl -sSLO https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/SHA256SUMS \
    && grep terragrunt_linux_${BUILD_ARCHITECTURE_ARCH} SHA256SUMS | sha256sum --check \
    && mv terragrunt_linux_${BUILD_ARCHITECTURE_ARCH} /usr/local/bin/terragrunt \
    && chmod +x /usr/local/bin/terragrunt \
    && rm -f SHA256SUMS


# ========================================
# KUBECTL https://dl.k8s.io/release/stable.txt
# ========================================


ENV KUBECTL_VERSION=1.32.1

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -sSLO https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${BUILD_ARCHITECTURE_ARCH}/kubectl \
    && curl -sSLO https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${BUILD_ARCHITECTURE_ARCH}/kubectl.sha256 \
    && bash -c 'echo "$(<kubectl.sha256) kubectl" | sha256sum --check' \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/ \
    && rm -f kubectl.sha256


# ========================================
# KUSTOMIZE https://github.com/kubernetes-sigs/kustomize/releases
# ========================================


ENV KUSTOMIZE_VERSION=5.6.0

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -sSLO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && curl -sSLO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/checksums.txt \
    && grep kustomize_v${KUSTOMIZE_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz checksums.txt | sha256sum --check \
    && tar -zxvf kustomize_v${KUSTOMIZE_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && chmod +x kustomize \
    && mv kustomize /usr/local/bin/ \
    && rm -f rm kustomize_v${KUSTOMIZE_VERSION}_* checksums.txt


# ========================================
# HELM https://github.com/helm/helm/releases
# ========================================

ENV HELM_VERSION=3.17.0

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -sSLO https://get.helm.sh/helm-v${HELM_VERSION}-linux-${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && curl -sSLO https://get.helm.sh/helm-v${HELM_VERSION}-linux-${BUILD_ARCHITECTURE_ARCH}.tar.gz.sha256sum \
    && sha256sum --check helm-v${HELM_VERSION}-linux-${BUILD_ARCHITECTURE_ARCH}.tar.gz.sha256sum \
    && tar zxvf helm-v${HELM_VERSION}-linux-${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && mv linux-${BUILD_ARCHITECTURE_ARCH}/helm /usr/local/bin/ \
    && rm -rf linux-${BUILD_ARCHITECTURE_ARCH} helm-v${HELM_VERSION}-linux-${BUILD_ARCHITECTURE_ARCH}* CHANGELOG.md \
    && echo "source <(helm completion bash)" >> ~/.bashrc

# ========================================
# Flux CD https://github.com/fluxcd/flux2/releases
# ========================================

ENV FLUXCD_VERSION=2.4.0

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -sSLO https://github.com/fluxcd/flux2/releases/download/v${FLUXCD_VERSION}/flux_${FLUXCD_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && curl -sSLO https://github.com/fluxcd/flux2/releases/download/v${FLUXCD_VERSION}/flux_${FLUXCD_VERSION}_checksums.txt \
    && grep flux_${FLUXCD_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz flux_${FLUXCD_VERSION}_checksums.txt | sha256sum --check \
    && tar zxvf flux_${FLUXCD_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && chmod +x flux \
    && mv flux /usr/local/bin/ \
    && rm -f flux_${FLUXCD_VERSION}_*

# ========================================
# Go https://go.dev/dl/
# ========================================

ENV GO_VERSION=1.23.5

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -sSLO https://go.dev/dl/go${GO_VERSION}.linux-${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && rm -f go${GO_VERSION}.linux-${BUILD_ARCHITECTURE_ARCH}.tar.gz

ENV PATH="${PATH}:/usr/local/go/bin"

# ========================================
# Eksctl https://github.com/eksctl-io/eksctl/releases
# ========================================

ENV EKSCTL_VERSION=0.202.0

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -sSLO https://github.com/eksctl-io/eksctl/releases/download/v${EKSCTL_VERSION}/eksctl_Linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && curl -sSLO https://github.com/eksctl-io/eksctl/releases/download/v${EKSCTL_VERSION}/eksctl_checksums.txt \
    && grep eksctl_Linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz eksctl_checksums.txt | sha256sum --check \
    && tar zxvf eksctl_Linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && chmod +x eksctl \
    && mv eksctl /usr/local/bin/ \
    && rm -f eksctl_Linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz eksctl_checksums.txt

# ========================================
# k9s https://github.com/derailed/k9s/releases
# ========================================

ENV K9S_VERSION=0.32.7

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -sSLO https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && curl -sSLO https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/checksums.sha256 \
    && grep k9s_Linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz checksums.sha256 | grep -v sbom | sha256sum --check \
    && tar zxvf k9s_Linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && chmod +x k9s \
    && mv k9s /usr/local/bin/ \
    && rm -rf LICENSE README.md k9s_Linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz checksums.sha256

# ========================================
# 1Password CLI https://app-updates.agilebits.com/product_history/CLI2
# ========================================
ENV OP_CLI_VERSION=v2.30.3

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -sSLO https://cache.agilebits.com/dist/1P/op2/pkg/${OP_CLI_VERSION}/op_linux_${BUILD_ARCHITECTURE_ARCH}_${OP_CLI_VERSION}.zip \
    && unzip -od /usr/local/bin/ op_linux_${BUILD_ARCHITECTURE_ARCH}_${OP_CLI_VERSION}.zip \
    && rm op_linux_${BUILD_ARCHITECTURE_ARCH}_${OP_CLI_VERSION}.zip

# ========================================
# Mimirtool https://github.com/grafana/mimir/releases/
# ========================================
ENV MIMIRTOOL_VERSION=2.14.3

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -sSLo mimirtool https://github.com/grafana/mimir/releases/download/mimir-${MIMIRTOOL_VERSION}/mimirtool-linux-${BUILD_ARCHITECTURE_ARCH} \
    && curl -sSLo mimirtool.sha256 https://github.com/grafana/mimir/releases/download/mimir-${MIMIRTOOL_VERSION}/mimirtool-linux-${BUILD_ARCHITECTURE_ARCH}-sha-256 \
    && bash -c 'echo "$(<mimirtool.sha256) mimirtool" | sha256sum --check' \
    && chmod +x mimirtool \
    && mv mimirtool /usr/local/bin/ \
    && rm -f mimirtool.sha256

# ========================================
# Azure CLI https://learn.microsoft.com/en-us/cli/azure/release-notes-azure-cli
# ========================================

# ENV AZ_VERSION=2.65.0 # Using latest stable version recommended by Microsoft

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# ========================================
# END
# ========================================

CMD [ "bash" ]
