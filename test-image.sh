# If any of these requirements fail the build will fail
aws --version \
&& terraform --version \
&& terragrunt --version \
&& kubectl version --client \
&& kustomize version \
&& helm version \
&& flux --version \
&& go version \
&& eksctl version \
&& k9s version
