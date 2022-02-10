# ========================================
# CREATE UPDATED BASE IMAGE
# ========================================

FROM debian:testing-slim AS base

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# ========================================
# GENERAL PREREQUISITES
# ========================================

FROM base

RUN apt-get update \
    && apt-get install -y curl unzip git bash-completion jq ssh sudo gnupg groff \
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

ENV AWS_CLI_VERSION=2.4.7

RUN curl -s https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip -o awscliv2.zip \
    && curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip.sig  -o awscliv2.sig \
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

ENV TERRAFORM_VERSION=1.1.2

RUN curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS \
    && curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig \
    && gpg --import hashicorp.asc \
    && gpg --verify terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig terraform_${TERRAFORM_VERSION}_SHA256SUMS \
    && grep terraform_${TERRAFORM_VERSION}_linux_amd64.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS > terraform_${TERRAFORM_VERSION}_SHA256SUM \
    && shasum -a 256 -c terraform_${TERRAFORM_VERSION}_SHA256SUM \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && rm -f terraform_${TERRAFORM_VERSION}_* hashicorp.asc \
    && mv terraform /usr/local/bin/ \
    && terraform -install-autocomplete


# ========================================
# TERRAGRUNT
# ========================================

ENV TERRAGRUNT_VERSION=0.35.16

RUN curl -Ls https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 -o terragrunt \
    && chmod +x terragrunt \
    && mv terragrunt /usr/local/bin/


# ========================================
# KUBECTL
# ========================================


ENV KUBECTL_VERSION=1.21.8

RUN curl -Ls https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o kubectl \
    && curl -Os https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256 \
    && bash -c 'echo "$(<kubectl.sha256) kubectl" | sha256sum --check' \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/ \
    && rm -f kubectl.sha256


# ========================================
# KUSTOMIZE
# ========================================


ENV KUSTOMIZE_VERSION=4.5.2

RUN curl -LOs https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz \
    && curl -Ls https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/checksums.txt -o kustomize_checksums.txt \
    && grep kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz kustomize_checksums.txt > kustomize_linux_amd64_checksum.txt \
    && shasum -a 256 -c kustomize_linux_amd64_checksum.txt \
    && tar -zxvf kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz \
    && rm kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz \
    && chmod +x kustomize \
    && mv kustomize /usr/local/bin/ \
    && rm -f kustomize_checksums.txt kustomize_linux_amd64_checksum.txt


# ========================================
# KUBECTL CROSSPLANE PLUGIN
# ========================================

ENV CROSSPLANE_VERSION=v1.5.1

RUN curl -Ls https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | CHANNEL=stable VERSION=${CROSSPLANE_VERSION} sh \
    && mv kubectl-crossplane /usr/local/bin


# ========================================
# HELM
# ========================================

ENV HELM_VERSION=3.7.2

RUN curl -Ls https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz -o helm.tgz \
    && tar -zxvf helm.tgz \
    && rm helm.tgz \
    && mv linux-amd64/helm /usr/local/bin/ \
    && rm -R linux-amd64 \
    && echo "source <(helm completion bash)" >> ~/.bashrc


# ========================================
# AWS IAM AUTHENTICATOR
# ========================================

ENV AWSIAMAUTH_VERSION=1.21.2/2021-07-05

RUN curl -Ls https://amazon-eks.s3-us-west-2.amazonaws.com/${AWSIAMAUTH_VERSION}/bin/linux/amd64/aws-iam-authenticator -o aws-iam-authenticator \
    && chmod +x aws-iam-authenticator \
    && mv aws-iam-authenticator /usr/local/bin/


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


ENV FLUXCD_VERSION=0.24.1

RUN curl -LOs https://github.com/fluxcd/flux2/releases/download/v${FLUXCD_VERSION}/flux_${FLUXCD_VERSION}_linux_amd64.tar.gz \
    && curl -LO https://github.com/fluxcd/flux2/releases/download/v${FLUXCD_VERSION}/flux_${FLUXCD_VERSION}_checksums.txt \
    && grep flux_${FLUXCD_VERSION}_linux_amd64.tar.gz flux_${FLUXCD_VERSION}_checksums.txt > flux_checksum.txt \
    && shasum -a 256 -c flux_checksum.txt \
    && tar zxvf flux_${FLUXCD_VERSION}_linux_amd64.tar.gz \
    && chmod +x flux \
    && mv flux /usr/local/bin/ \
    && rm -f flux_checksum.txt flux_${FLUXCD_VERSION}_linux_amd64.tar.gz flux_${FLUXCD_VERSION}_checksums.txt

# ========================================
# END
# ========================================

CMD [ "bash" ]
