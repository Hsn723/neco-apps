# Makefile to update manifests

HELM_VERSION = 3.5.2

.PHONY: all
all:
	@echo Read docs/maintenance.md for the usage

.PHONY: update-argocd
update-argocd:
	$(call get-latest-tag,argocd)
	curl -sLf -o argocd/base/upstream/install.yaml \
		https://raw.githubusercontent.com/argoproj/argo-cd/$(call upstream-tag,$(latest_tag))/manifests/install.yaml
	sed -i -E '/name:.*argocd$$/!b;n;s/newTag:.*$$/newTag: $(latest_tag)/' argocd/base/kustomization.yaml
	$(call get-latest-tag,dex)
	sed -i -E '/name:.*dex$$/!b;n;s/newTag:.*$$/newTag: $(latest_tag)/' argocd/base/kustomization.yaml
	$(call get-latest-tag,redis)
	sed -i -E '/name:.*redis$$/!b;n;s/newTag:.*$$/newTag: $(latest_tag)/' argocd/base/kustomization.yaml

.PHONY: update-cert-manager
update-cert-manager:
	$(call get-latest-tag,cert-manager)
	curl -sLf -o cert-manager/base/upstream/cert-manager.yaml \
		https://github.com/jetstack/cert-manager/releases/download/$(call upstream-tag,$(latest_tag))/cert-manager.yaml
	sed -i -E 's/newTag:.*$$/newTag: $(latest_tag)/' cert-manager/base/kustomization.yaml

.PHONY: update-customer-egress
update-customer-egress:
	curl -sLf -o customer-egress/base/neco/squid.yaml \
		https://raw.githubusercontent.com/cybozu-go/neco/release/etc/squid.yml
	sed -e 's/internet-egress/customer-egress/g' \
		-e 's,{{ .squid }},quay.io/cybozu/squid,g' \
		-e 's,{{ index . "cke-unbound" }},quay.io/cybozu/unbound,g' \
		-e '/nodePort: 30128/d' customer-egress/base/neco/squid.yaml > customer-egress/base/squid.yaml
	$(call get-latest-tag,squid)
	sed -i -E '/name:.*squid$$/!b;n;s/newTag:.*$$/newTag: $(latest_tag)/' customer-egress/base/kustomization.yaml
	$(call get-latest-tag,unbound)
	sed -i -E '/name:.*unbound$$/!b;n;s/newTag:.*$$/newTag: $(latest_tag)/' customer-egress/base/kustomization.yaml

.PHONY: update-external-dns
update-external-dns:
	$(call get-latest-tag,external-dns)
	curl -sLf -o external-dns/base/upstream/crd.yaml \
		https://raw.githubusercontent.com/kubernetes-sigs/external-dns/$(call upstream-tag,$(latest_tag))/docs/contributing/crd-source/crd-manifest.yaml
	sed -i -E 's,quay.io/cybozu/external-dns:.*$$,quay.io/cybozu/external-dns:$(latest_tag),' external-dns/base/deployment.yaml

.PHONY: update-grafana-operator
update-grafana-operator:
	$(call get-latest-tag,grafana-operator)
	rm -rf /tmp/grafana-operator
	cd /tmp; git clone --depth 1 -b $(call upstream-tag,$(latest_tag)) https://github.com/integr8ly/grafana-operator
	rm -rf monitoring/base/grafana-operator/upstream/*
	cp -r /tmp/grafana-operator/deploy/crds monitoring/base/grafana-operator/upstream
	cp -r /tmp/grafana-operator/deploy/cluster_roles monitoring/base/grafana-operator/upstream
	cp -r /tmp/grafana-operator/deploy/roles monitoring/base/grafana-operator/upstream
	cp /tmp/grafana-operator/deploy/operator.yaml monitoring/base/grafana-operator/upstream
	rm -rf /tmp/grafana-operator
	sed -i -E '/newName:.*grafana-operator$$/!b;n;s/newTag:.*$$/newTag: $(latest_tag)/' monitoring/base/kustomization.yaml

.PHONY: update-kube-metrics-adapter
update-kube-metrics-adapter:
	$(call get-latest-tag,kube-metrics-adapter)
	rm -rf /tmp/kube-metrics-adapter
	cd /tmp; git clone -b $(call upstream-tag,$(latest_tag)) --depth 1 https://github.com/zalando-incubator/kube-metrics-adapter
	helm template \
		--set namespace=kube-metrics-adapter \
		--set enableExternalMetricsApi=true \
		--set service.internalPort=6443 \
		--set replicas=2 \
		/tmp/kube-metrics-adapter/docs/helm > kube-metrics-adapter/base/upstream/manifest.yaml
	rm -rf /tmp/kube-metrics-adapter
	sed -i 's/newTag: .*/newTag: $(latest_tag)/' kube-metrics-adapter/base/kustomization.yaml

.PHONY: update-kube-state-metrics
update-kube-state-metrics:
	$(call get-latest-tag,kube-state-metrics)
	rm -rf /tmp/kube-state-metrics
	cd /tmp; git clone --depth 1 -b $(call upstream-tag,$(latest_tag)) https://github.com/kubernetes/kube-state-metrics
	rm -f monitoring/base/kube-state-metrics/*
	cp /tmp/kube-state-metrics/examples/standard/* monitoring/base/kube-state-metrics
	rm -rf /tmp/kube-state-metrics
	sed -i -E '/newName:.*kube-state-metrics$$/!b;n;s/newTag:.*$$/newTag: $(latest_tag)/' monitoring/base/kustomization.yaml

.PHONY: update-machines-endpoints
update-machines-endpoints:
	$(call get-latest-tag,machines-endpoints)
	sed -i -E 's,image: quay.io/cybozu/machines-endpoints:.*$$,image: quay.io/cybozu/machines-endpoints:$(latest_tag),' bmc-reverse-proxy/base/machines-endpoints/cronjob.yaml
	sed -i -E 's,image: quay.io/cybozu/machines-endpoints:.*$$,image: quay.io/cybozu/machines-endpoints:$(latest_tag),' monitoring/base/machines-endpoints/cronjob.yaml

.PHONY: update-metallb
update-metallb:
	$(call get-latest-tag,metallb)
	rm -rf /tmp/metallb
	cd /tmp; git clone --depth 1 -b $(call upstream-tag,$(latest_tag)) https://github.com/metallb/metallb
	rm -f metallb/base/upstream/*
	cp /tmp/metallb/manifests/*.yaml metallb/base/upstream
	rm -rf /tmp/metallb
	sed -i -E 's/newTag:.*$$/newTag: $(latest_tag)/' metallb/base/kustomization.yaml

.PHONY: update-moco
update-moco:
	$(call get-latest-gh,cybozu-go/moco)
	rm -rf /tmp/moco
	cd /tmp; git clone --depth 1 -b $(latest_gh) https://github.com/cybozu-go/moco
	rm -rf moco/base/upstream/*
	cp -r /tmp/moco/config/* moco/base/upstream
	rm -rf /tmp/moco
	sed -i -E 's/newTag:.*$$/newTag: $(patsubst v%,%,$(latest_gh))/' moco/base/kustomization.yaml

.PHONY: update-prometheus-adapter
update-prometheus-adapter:
	$(call get-latest-tag,prometheus-adapter)
	sed -i -E \
		-e 's/^(          tag:).*$$/\1 $(latest_tag)/' \
		-e 's/^(    targetRevision:).*$$/\1 $(CHART_VERSION)/' \
		argocd-config/base/prometheus-adapter.yaml
	rm -rf /tmp/prometheus-adapter

# usage: get-latest-tag NAME
define get-latest-tag
$(eval latest_tag := $(shell curl -sf https://quay.io/api/v1/repository/cybozu/$1/tag/ | jq -r '.tags[] | .name' | awk '/.*\..*\./ {print $$1; exit}'))
endef

# usage: upstream-tag 1.2.3.4
define upstream-tag
$(shell echo $1 | sed -E 's/^(.*)\.[[:digit:]]+$$/v\1/')
endef

# usage get-latest-gh OWNER/REPO
define get-latest-gh
$(eval latest_gh := $(shell curl -sf https://api.github.com/repos/$1/releases/latest | jq -r '.tag_name'))
endef

.PHONY: setup
setup:
	curl -o /tmp/helm.tgz -fsL https://get.helm.sh/helm-v$(HELM_VERSION)-linux-amd64.tar.gz
	mkdir -p $$(go env GOPATH)/bin
	tar --strip-components=1 -C $$(go env GOPATH)/bin -xzf /tmp/helm.tgz linux-amd64/helm
	rm -f /tmp/helm.tgz
