FROM ruby:2.4.4-alpine3.7

ENV TERRAFORM_VERSION=0.11.7 \
    TERRAGRUNT_VERSION=0.14.0 \
    KUBECTL_VERSION=1.9.8 \
    KOPS_VERSION=1.8.1 \
    HELM_VERSION=2.8.2 \
    AWSCLI_VERSION=1.15.45 \
    RAKE_VERSION=12.3.0 \
    PATH=${PATH}:/opt/bin

COPY . /gpii-infra

RUN apk add --update --no-cache \
      bash \
      python \
      py-yaml \
      py-pip \
      jq \
      openssh-client \
    && wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -O /tmp/terraform.zip \
    && mkdir -p /opt/bin \
    && unzip /tmp/terraform.zip -d /opt/bin \
    && rm /tmp/terraform.zip \
    && wget https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 -O /opt/bin/terragrunt \
    && chmod +x /opt/bin/terragrunt \
    && wget https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -O /opt/bin/kubectl \
    && chmod +x /opt/bin/kubectl \
    && wget https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64 -O /opt/bin/kops \
    && chmod +x /opt/bin/kops \
    && wget https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz -O- | tar xvz linux-amd64/helm --strip-components=1 -C /opt/bin \
    && pip install --upgrade pip \
    && pip install awscli=="${AWSCLI_VERSION}" \
    && gem install rake -v "${RAKE_VERSION}" \
    && cd /gpii-infra/aws/dev \
    && bundle install --path vendor/bundle

WORKDIR /gpii-infra/aws/dev

ENTRYPOINT ["/bin/bash", "-c"]
