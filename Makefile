.DEFAULT_GOAL := help

RELEASE_VERSION ?= 0.3.0
ADDLICENSE ?= go run -modfile hack/tools/go.mod github.com/google/addlicense


copyright: ## Apply copyright notice (header) to all source code.
	$(ADDLICENSE) -f ./hack/copyright.txt .


check: ## Run linters against the codebase.
	hack/check/check-mdlint.sh
	hack/check/check-yaml.sh

bundle: bundle-all ## Generate packaging and imgpkg bundles from ./src

# pre-requisites:
#
# 	- BUNDLE environment variable: must be set to point at the image
# 	registry where these bundles should be published at. Ideally this is
# 	either a local image registry or a development one where non-final
# 	versions are pushed to.
#
#        e.g.: to publish all imgpkg bundles to a local registry under
#        192.168.0.10 naming the images after `test`:
#
#        	BUNDLE=192.168.0.10:5000/test make bundle
#
bundle-all: bundle-cartographer bundle-cartographer-tce bundle-cartographer-catalog bundle-cartographer-catalog-tce


relocate: relocate-all ## Relocate bundles from temporary to final registries.
.PHONY: relocate

# pre-requisites:
#
# 	- `./release` to be populated with the packages and bundle.tar files
# 	- credentials for the registries to be made available for imgpkg
# 	- access to the registries (e.g., vmware's require that pushes
# 	  originate from within the VMware internal network).
#
relocate-all: relocate-cartographer relocate-cartographer-tce relocate-cartographer-catalog relocate-cartographer-catalog-tce


# ps.:  This target expects that:
# 	1.
#
publish: ## Gen release notes and publish to GitHub
	./hack/publish.sh v$(RELEASE_VERSION)


bundle-cartographer:
	DIR=./src/cartographer \
	NAME=cartographer \
	PACKAGE_NAME=cartographer.tanzu.vmware.com \
	RELEASE_VERSION=$(RELEASE_VERSION) \
		./hack/bundle.sh

bundle-cartographer-tce:
	DIR=./src/cartographer \
	NAME=cartographer-tce \
	PACKAGE_NAME=cartographer.community.tanzu.vmware.com \
	RELEASE_VERSION=$(RELEASE_VERSION) \
		./hack/bundle.sh

bundle-cartographer-catalog:
	DIR=./src/cartographer-catalog \
	NAME=cartographer-catalog \
	PACKAGE_NAME=cartographer-catalog.tanzu.vmware.com \
	RELEASE_VERSION=$(RELEASE_VERSION) \
		./hack/bundle.sh

bundle-cartographer-catalog-tce:
	DIR=./src/cartographer-catalog \
	NAME=cartographer-catalog-tce \
	PACKAGE_NAME=cartographer-catalog.community.tanzu.vmware.com \
	RELEASE_VERSION=$(RELEASE_VERSION) \
		./hack/bundle.sh


relocate-cartographer:
	BUNDLE=projectcartographer/cartographer \
	DIR=./release/cartographer \
	RELEASE_VERSION=$(RELEASE_VERSION) \
		./hack/relocate.sh

relocate-cartographer-catalog:
	BUNDLE=projectcartographer/cartographer \
	DIR=./release/cartographer-catalog \
	RELEASE_VERSION=$(RELEASE_VERSION) \
		./hack/relocate.sh

relocate-cartographer-tce:
	BUNDLE=projects.registry.vmware.com/tce/cartographer \
	DIR=./release/cartographer-tce \
	RELEASE_VERSION=$(RELEASE_VERSION) \
		./hack/relocate.sh

relocate-cartographer-catalog-tce:
	BUNDLE=projects.registry.vmware.com/tce/cartographer \
	DIR=./release/cartographer-catalog-tce \
	RELEASE_VERSION=$(RELEASE_VERSION) \
		./hack/relocate.sh



# Absolutely awesome: http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Print help for each make target
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
