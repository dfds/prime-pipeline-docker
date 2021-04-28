# ========================================
# CREATE UPDATED BASE IMAGE
# ========================================

FROM debian:stretch-slim AS base

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# ========================================
# GENERAL PREREQUISITES
# ========================================

FROM base

RUN apt-get update \
    && apt-get install -y curl unzip git bash-completion jq ssh sudo gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Adding  GitHub public SSH key to known hosts
RUN ssh -T -o "StrictHostKeyChecking no" -o "PubkeyAuthentication no" git@github.com || true

# ========================================
# COPY FILES
# ========================================

ADD src/*.asc /

# # ========================================
# # PYTHON
# # ========================================

# RUN apt-get update \
#     && apt-get install -y python python-pip python3 python3-pip \
#     && apt-get clean \
#     && rm -rf /var/lib/apt/lists/*

# ========================================
# AWS CLI
# ========================================

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.2.0.zip" -o "awscliv2.zip" \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.2.0.zip.sig"  -o "awscliv2.sig" \
    && gpg --import aws-cli.asc \
    && gpg --verify awscliv2.sig awscliv2.zip \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf ./aws \
    && rm -f awscliv2.zip aws-cli.asc awscliv2.sig

ENV AWS_PAGER=""

# ========================================
# AZURE CLI
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest
# ========================================

ENV AZURECLI_VERSION=2.5.0-1~stretch

RUN apt-get update \
    && apt-get install -y ca-certificates curl apt-transport-https lsb-release

RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null


RUN AZ_REPO=$(lsb_release -cs) \
    && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list

RUN apt-get update \
    && apt-get install azure-cli=${AZURECLI_VERSION} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ========================================
# TERRAFORM
# ========================================

ENV TERRAFORM_VERSION=0.13.7

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

ENV TERRAGRUNT_VERSION=0.25.5

RUN curl -L https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 -o terragrunt \
    && chmod +x terragrunt \
    && mv terragrunt /usr/local/bin/


# ========================================
# KUBECTL
# ========================================


ENV KUBECTL_VERSION=1.20.6

RUN curl -L https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o kubectl \
    && curl -Os https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256 \
    && bash -c 'echo "$(<kubectl.sha256) kubectl" | sha256sum --check' \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/ \
    && rm -f kubectl.sha256

# ========================================
# KUBECTL CROSSPLANE PLUGIN
# ========================================

RUN curl -sL https://raw.githubusercontent.com/crossplane/crossplane/release-1.0/install.sh | sh \
    && mv kubectl-crossplane /usr/local/bin


# ========================================
# HELM
# ========================================

ENV HELM_VERSION=3.4.0

RUN curl -L https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz -o helm.tgz \
    && tar -zxvf helm.tgz \
    && rm helm.tgz \
    && mv linux-amd64/helm /usr/local/bin/ \
    && rm -R linux-amd64 \
    && echo "source <(helm completion bash)" >> ~/.bashrc


# ========================================
# KOPS
# ========================================

# ENV KOPS_VERSION=1.11.0

# RUN curl -L https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64 -o kops \
#     && chmod +x ./kops \
#     && mv ./kops /usr/local/bin/ \
#     && echo "source <(kops completion bash)" >> ~/.bashrc


# ========================================
# AWS IAM AUTHENTICATOR
# ========================================

ENV AWSIAMAUTH_VERSION=1.15.10/2020-02-22

RUN curl -L https://amazon-eks.s3-us-west-2.amazonaws.com/${AWSIAMAUTH_VERSION}/bin/linux/amd64/aws-iam-authenticator -o aws-iam-authenticator \
    && chmod +x aws-iam-authenticator \
    && mv aws-iam-authenticator /usr/local/bin/


# ========================================
# SAML2AWS
# ========================================

# ENV SAML2AWS_VERSION=2.13.0

# RUN curl -L "https://github.com/Versent/saml2aws/releases/download/v${SAML2AWS_VERSION}/saml2aws_${SAML2AWS_VERSION}_linux_amd64.tar.gz" -o saml2aws.tar.gz \
#     && tar -zxvf saml2aws.tar.gz \
#     && rm saml2aws.tar.gz \
#     && mv saml2aws /usr/local/bin/


# ========================================
# INSPEC
# ========================================

# TBD


# ========================================
# ARGO CD CLI
# ========================================

# ENV ARGOCDCLI_VERSION=0.12.0

# RUN curl -L https://github.com/argoproj/argo-cd/releases/download/v${ARGOCDCLI_VERSION}/argocd-linux-amd64 -o argocd \
#     && chmod +x argocd \
#     && mv argocd /usr/local/bin/


# ========================================
# KAFKA MESSAGE PRODUCER
# ========================================

RUN apt-get update \
    && apt-get install -y kafkacat \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# ========================================
# END
# ========================================

CMD [ "bash" ]

# ========================================
# ISSUES
# ========================================

# debconf: unable to initialize frontend: Dialog
# debconf: (TERM is not set, so the dialog frontend is not usable.)
# debconf: falling back to frontend: Readline
# debconf: unable to initialize frontend: Readline
# debconf: (Can't locate Term/ReadLine.pm in @INC (you may need to install the Term::ReadLine module) (@INC contains: /etc/perl /usr/local/lib/x86_64-linux-gnu/perl/5.24.1 /usr/local/share/perl/5.24.1 /usr/lib/x86_64-linux-gnu/perl5/5.24 /usr/share/perl5 /usr/lib/x86_64-linux-gnu/perl/5.24 /usr/share/perl/5.24 /usr/local/lib/site_perl /usr/lib/x86_64-linux-gnu/perl-base .) at /usr/share/perl5/Debconf/FrontEnd/Readline.pm line 7, <> line 3.)
# debconf: falling back to frontend: Teletype
# dpkg-preconfigure: unable to re-open stdin:
