FROM alpine

ENV HELM_VERSION=2.12.0

RUN set -x && \
	apk add --update bash git jq && \
	wget "https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz" && \
	tar -zxf "helm-v${HELM_VERSION}-linux-amd64.tar.gz" && \
	mv linux-amd64/helm /usr/local/bin/helm && \
	chmod +x /usr/local/bin/helm
