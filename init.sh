#!/bin/bash

# ========================================
# FETCH LATEST PACKAGE LISTS
# ========================================

apt-get update

# ========================================
# GENERAL PREREQUISITES
# ========================================

apt-get install -y --no-install-recommends curl unzip git bash-completion jq ssh sudo

# Adding  GitHub public SSH key to known hosts
ssh -T -o "StrictHostKeyChecking no" -o "PubkeyAuthentication no" git@github.com || true


# # ========================================
# # PYTHON
# # ========================================

# apt-get install -y --no-install-recommends python python-pip python3 python3-pip


# ========================================
# AWS CLI
# ========================================

# Always install newest version
# Doesn't seem to allow version lock https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf ./aws
rm awscliv2.zip

export AWS_PAGER=""


# ========================================
# AZURE CLI
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest
# ========================================

apt-get install -y --no-install-recommends ca-certificates curl apt-transport-https lsb-release gnupg
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null
AZ_REPO=$(lsb_release -cs) && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list
apt-get install -y --no-install-recommends azure-cli=${AZURECLI_VERSION}


# ========================================
# TERRAFORM
# ========================================

curl -L https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip
unzip terraform.zip
rm terraform.zip
mv terraform /usr/local/bin/
terraform -install-autocomplete


# ========================================
# TERRAGRUNT
# ========================================

curl -L https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 -o terragrunt
chmod +x terragrunt
mv terragrunt /usr/local/bin/


# ========================================
# KUBECTL
# ========================================

curl -L https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/


# ========================================
# HELM
# ========================================

curl -L https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz -o helm.tgz
tar -zxvf helm.tgz
rm helm.tgz
mv linux-amd64/helm /usr/local/bin/
rm -R linux-amd64
echo "source <(helm completion bash)" >> ~/.bashrc


# ========================================
# KOPS
# ========================================

# curl -L https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64 -o kops
# chmod +x ./kops
# mv ./kops /usr/local/bin/
# echo "source <(kops completion bash)" >> ~/.bashrc


# ========================================
# AWS IAM AUTHENTICATOR
# ========================================

curl -L https://amazon-eks.s3-us-west-2.amazonaws.com/${AWSIAMAUTH_VERSION}/bin/linux/amd64/aws-iam-authenticator -o aws-iam-authenticator
chmod +x aws-iam-authenticator
mv aws-iam-authenticator /usr/local/bin/


# ========================================
# SAML2AWS
# ========================================

# curl -L "https://github.com/Versent/saml2aws/releases/download/v${SAML2AWS_VERSION}/saml2aws_${SAML2AWS_VERSION}_linux_amd64.tar.gz" -o saml2aws.tar.gz
# tar -zxvf saml2aws.tar.gz
# rm saml2aws.tar.gz
# mv saml2aws /usr/local/bin/


# ========================================
# INSPEC
# ========================================

# TBD


# ========================================
# ARGO CD CLI
# ========================================

# curl -L https://github.com/argoproj/argo-cd/releases/download/v${ARGOCDCLI_VERSION}/argocd-linux-amd64 -o argocd
# chmod +x argocd
# mv argocd /usr/local/bin/


# ========================================
# KAFKA MESSAGE PRODUCER
# ========================================

apt-get install -y --no-install-recommends kafkacat


# ========================================
# CLEANUP
# ========================================

apt-get clean
rm -rf /var/lib/apt/lists/*
