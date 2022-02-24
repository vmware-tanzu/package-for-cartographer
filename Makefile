ADDLICENSE ?= go run -modfile hack/tools/go.mod github.com/google/addlicense


.PHONY: copyright
copyright:
	$(ADDLICENSE) -f ./hack/copyright.txt .


install:
	./hack/bundle.sh
	ytt \
		--ignore-unknown-comments \
		-f ./src/ootb-supply-chains \
		--data-value registry.server=foo \
		--data-value registry.repository=bah
