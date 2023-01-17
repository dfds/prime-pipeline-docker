# ========================================
# CREATE UPDATED BASE IMAGE
# ========================================

FROM mcr.microsoft.com/powershell:debian-bullseye-slim AS base

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# ========================================
# GENERAL PREREQUISITES
# ========================================

FROM base

RUN apt-get update \
    && apt-get install -y curl unzip git bash-completion jq ssh sudo gnupg groff golang \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Adding  GitHub public SSH key to known hosts
RUN ssh -T -o "StrictHostKeyChecking no" -o "PubkeyAuthentication no" git@github.com || true

# ========================================
# COPY FILES
# ========================================

ADD src /

# ========================================
# AWS CLI
# ========================================

ENV AWS_CLI_VERSION=2.7.35

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -s https://awscli.amazonaws.com/awscli-exe-linux-${BUILD_ARCHITECTURE}-${AWS_CLI_VERSION}.zip -o awscliv2.zip \
    && curl https://awscli.amazonaws.com/awscli-exe-linux-${BUILD_ARCHITECTURE}-${AWS_CLI_VERSION}.zip.sig  -o awscliv2.sig \
    && gpg --import aws-cli.asc \
    && gpg --verify awscliv2.sig awscliv2.zip \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf ./aws \
    && rm -f awscliv2.zip aws-cli.asc awscliv2.sig

ENV AWS_PAGER=""

ENV AWSPOWERSHELL_VERSION=4.1.14

RUN pwsh -Command $ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; Install-Module AWSPowerShell.NetCore -Scope AllUsers -AcceptLicense -Force -RequiredVersion ${AWSPOWERSHELL_VERSION}

# ========================================
# TERRAFORM
# ========================================

ENV TERRAFORM_VERSION=1.2.2

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.zip \
    && curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS \
    && curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig \
    && gpg --import hashicorp.asc \
    && gpg --verify terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig terraform_${TERRAFORM_VERSION}_SHA256SUMS \
    && grep terraform_${TERRAFORM_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS > terraform_${TERRAFORM_VERSION}_SHA256SUM \
    && shasum -a 256 -c terraform_${TERRAFORM_VERSION}_SHA256SUM \
    && unzip terraform_${TERRAFORM_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.zip \
    && rm -f terraform_${TERRAFORM_VERSION}_* hashicorp.asc \
    && mv terraform /usr/local/bin/ \
    && terraform -install-autocomplete


# ========================================
# TERRAGRUNT
# ========================================

ENV TERRAGRUNT_VERSION=0.37.3

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -Ls https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_${BUILD_ARCHITECTURE_ARCH} -o terragrunt \
    && chmod +x terragrunt \
    && mv terragrunt /usr/local/bin/


# ========================================
# KUBECTL
# ========================================


ENV KUBECTL_VERSION=1.23.15

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -Ls https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/${BUILD_ARCHITECTURE_ARCH}/kubectl -o kubectl \
    && curl -Os https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/${BUILD_ARCHITECTURE_ARCH}/kubectl.sha256 \
    && bash -c 'echo "$(<kubectl.sha256) kubectl" | sha256sum --check' \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/ \
    && rm -f kubectl.sha256


# ========================================
# KUSTOMIZE
# ========================================


ENV KUSTOMIZE_VERSION=4.5.5

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -LOs https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && curl -Ls https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/checksums.txt -o kustomize_checksums.txt \
    && grep kustomize_v${KUSTOMIZE_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz kustomize_checksums.txt > kustomize_linux_${BUILD_ARCHITECTURE_ARCH}_checksum.txt \
    && shasum -a 256 -c kustomize_linux_${BUILD_ARCHITECTURE_ARCH}_checksum.txt \
    && tar -zxvf kustomize_v${KUSTOMIZE_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && rm kustomize_v${KUSTOMIZE_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && chmod +x kustomize \
    && mv kustomize /usr/local/bin/ \
    && rm -f kustomize_checksums.txt kustomize_linux_${BUILD_ARCHITECTURE_ARCH}_checksum.txt


# ========================================
# KUBECTL CROSSPLANE PLUGIN
# ========================================

ENV CROSSPLANE_VERSION=v1.8.1

RUN curl -Ls https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | CHANNEL=stable VERSION=${CROSSPLANE_VERSION} sh \
    && mv kubectl-crossplane /usr/local/bin


# ========================================
# HELM
# ========================================

ENV HELM_VERSION=3.7.2

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -Ls https://get.helm.sh/helm-v${HELM_VERSION}-linux-${BUILD_ARCHITECTURE_ARCH}.tar.gz -o helm.tgz \
    && tar -zxvf helm.tgz \
    && rm helm.tgz \
    && mv linux-${BUILD_ARCHITECTURE_ARCH}/helm /usr/local/bin/ \
    && rm -R linux-${BUILD_ARCHITECTURE_ARCH} \
    && echo "source <(helm completion bash)" >> ~/.bashrc


# ========================================
# KAFKA MESSAGE PRODUCER
# ========================================

RUN apt-get update \
    && apt-get install -y kafkacat \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ========================================
# Flux CD
# ========================================


ENV FLUXCD_VERSION=0.38.2

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -LOs https://github.com/fluxcd/flux2/releases/download/v${FLUXCD_VERSION}/flux_${FLUXCD_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && curl -LO https://github.com/fluxcd/flux2/releases/download/v${FLUXCD_VERSION}/flux_${FLUXCD_VERSION}_checksums.txt \
    && grep flux_${FLUXCD_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz flux_${FLUXCD_VERSION}_checksums.txt > flux_checksum.txt \
    && shasum -a 256 -c flux_checksum.txt \
    && tar zxvf flux_${FLUXCD_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && chmod +x flux \
    && mv flux /usr/local/bin/ \
    && rm -f flux_checksum.txt flux_${FLUXCD_VERSION}_linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz flux_${FLUXCD_VERSION}_checksums.txt

# ========================================
# END
# ========================================

CMD [ "bash" ]
