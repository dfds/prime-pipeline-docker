# ========================================
# CREATE UPDATED BASE IMAGE
# ========================================

FROM debian:bullseye-slim AS base

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# ========================================
# GENERAL PREREQUISITES
# ========================================

FROM base

RUN apt-get update \
    && apt-get install -y curl unzip git bash-completion jq ssh sudo gnupg groff gcc vim python3 python3-pip \
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

ENV AWS_CLI_VERSION=2.13.29

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


# ========================================
# TERRAFORM
# ========================================

ENV TERRAFORM_VERSION=1.4.6

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

ENV TERRAGRUNT_VERSION=0.45.16

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -Ls https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_${BUILD_ARCHITECTURE_ARCH} -o terragrunt \
    && chmod +x terragrunt \
    && mv terragrunt /usr/local/bin/


# ========================================
# KUBECTL
# ========================================


ENV KUBECTL_VERSION=1.28.3

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


ENV KUSTOMIZE_VERSION=5.2.1

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
# HELM
# ========================================

ENV HELM_VERSION=3.13.1

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
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/kafkacat /usr/bin/kcat

# ========================================
# Flux CD
# ========================================

ENV FLUXCD_VERSION=2.1.2

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
# Go
# ========================================

ENV GO_VERSION=1.19.5

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -LOs https://go.dev/dl/go${GO_VERSION}.linux-${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && rm -f go${GO_VERSION}.linux-${BUILD_ARCHITECTURE_ARCH}.tar.gz

ENV PATH="${PATH}:/usr/local/go/bin"

# ========================================
# Eksctl
# ========================================

ENV EKSCTL_VERSION=0.163.0

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -LOs https://github.com/weaveworks/eksctl/releases/download/v${EKSCTL_VERSION}/eksctl_Linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && curl -LO https://github.com/weaveworks/eksctl/releases/download/v${EKSCTL_VERSION}/eksctl_checksums.txt \
    && grep eksctl_Linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz eksctl_checksums.txt > eksctl_checksum.txt \
    && shasum -a 256 -c eksctl_checksum.txt \
    && tar zxvf eksctl_Linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz \
    && chmod +x eksctl \
    && mv eksctl /usr/local/bin/ \
    && rm -f eksctl_checksum.txt eksctl_Linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz eksctl_checksums.txt

# ========================================
# k9s
# ========================================

ENV K9S_VERSION=0.27.4

RUN export BUILD_ARCHITECTURE=$(uname -m); \
    if [ "$BUILD_ARCHITECTURE" = "x86_64" ]; then export BUILD_ARCHITECTURE_ARCH=amd64; fi; \
    if [ "$BUILD_ARCHITECTURE" = "aarch64" ]; then export BUILD_ARCHITECTURE_ARCH=arm64; fi; \
    curl -Ls https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_${BUILD_ARCHITECTURE_ARCH}.tar.gz -o k9s.tar.gz \
    && tar zxvf k9s.tar.gz \
    && chmod +x k9s \
    && rm -rf k9s.tar.gz LICENSE README.md \
    && mv k9s /usr/local/bin/



# ========================================
# Azure CLI
# ========================================

ENV AZ_VERSION=2.58.0

RUN pip3 install azure-cli==${AZ_VERSION}

# ========================================
# Scripts
# ========================================

COPY src/scripts /usr/local/bin

# ========================================
# END
# ========================================

CMD [ "bash" ]
