#!/bin/bash

set -eo pipefail

if [[ -z $LEVER_KUBECONFIG ]]; then
        echo "LEVER_KUBECONFIG must be set"
        exit 1
fi
if [[ -z $NEW_CARTOGRAPHER_IMAGE ]]; then
        echo "NEW_CARTOGRAPHER_IMAGE must be set"
        exit 1
fi
if [[ -z $CARTOGRAPHER_LEVER_BUILD_ID ]]; then
        echo "CARTOGRAPHER_LEVER_BUILD_ID must be set"
        exit 1
fi

readonly REGISTRY_HOST=${REGISTRY_HOST:-"harbor-repo.vmware.com"}
readonly REGISTRY_PROJECT=${REGISTRY_PROJECT:-'supply-chain-choreographer/package-for-cartographer'}
readonly PACKAGE_GIT_COMMIT=${PACKAGE_GIT_COMMIT:-$(git rev-parse HEAD)}
readonly PACKAGE_NAME=${PACKAGE_NAME:-'package-for-cartographer'}
readonly PACKAGE_VERSION=${PACKAGE_VERSION:-$(git describe --tags --abbrev=0)}
readonly OFFICIAL_BUILD=${OFFICIAL_BUILD:-False}
readonly OLD_CARTOGRAPHER_IMAGE=${OLD_CARTOGRAPHER_IMAGE:-'projectcartographer/cartographer:latest'}

echo "REGISTRY_HOST: $REGISTRY_HOST"
echo "REGISTRY_PROJECT: $REGISTRY_PROJECT"
echo "PACKAGE_GIT_COMMIT: $PACKAGE_GIT_COMMIT"
echo "PACKAGE_NAME: $PACKAGE_NAME"
echo "PACKAGE_VERSION: $PACKAGE_VERSION"
echo "OFFICIAL_BUILD: $OFFICIAL_BUILD"
echo "OLD_CARTOGRAPHER_IMAGE: $OLD_CARTOGRAPHER_IMAGE"
echo "NEW_CARTOGRAPHER_IMAGE: $NEW_CARTOGRAPHER_IMAGE"
echo "CARTOGRAPHER_LEVER_BUILD_ID: $CARTOGRAPHER_LEVER_BUILD_ID"

ytt -f build-templates/kbld-config.yaml -f build-templates/values-schema.yaml -v build.registry_host=${REGISTRY_HOST} -v build.registry_project=${REGISTRY_PROJECT} > kbld-config.yaml
ytt -f build-templates/package-build.yml -f build-templates/values-schema.yaml -v build.registry_host=${REGISTRY_HOST} -v build.registry_project=${REGISTRY_PROJECT} > package-build.yml
ytt -f build-templates/package-resources.yml -f build-templates/values-schema.yaml > package-resources.yml

lever_build_request() {
        readonly BUILD_SUFFIX="$(git rev-parse HEAD | head -c 6)-$(echo $RANDOM | shasum | head -c 6; echo)"
        ytt --ignore-unknown-comments -f ./hack/lever/lever_build_request.yaml \
        --data-value bundle_name=$PACKAGE_NAME \
        --data-value build_suffix=$BUILD_SUFFIX \
        --data-value imgpkg_bundle_repo="${REGISTRY_HOST}/${REGISTRY_PROJECT}:${PACKAGE_VERSION}" \
        --data-value commit_ref=$PACKAGE_GIT_COMMIT \
        --data-value component_image_name=$NEW_CARTOGRAPHER_IMAGE \
        --data-value kbld_source=$OLD_CARTOGRAPHER_IMAGE \
        --data-value cartographer_request_name=$CARTOGRAPHER_LEVER_BUILD_ID \
        --data-value-yaml official_build=$OFFICIAL_BUILD \
        | kubectl --kubeconfig <(printf "${LEVER_KUBECONFIG}") apply -f -
        wait_for_lever_build "$PACKAGE_NAME-$BUILD_SUFFIX"
}

wait_for_lever_build() {
        local build_name=$1
        local conditions_json=""
        local components_status="-- "
        local build_status="-- "
        local srp_status="-- "
        local ready_status="-- "

        local counter=1

        echo "Waiting for lever build $build_name to complete..."
        while [[ $ready_status != 'False' && $ready_status != 'True' ]]; do
                conditions_json=$(kubectl --kubeconfig <(printf "${LEVER_KUBECONFIG}") get request/$build_name -o jsonpath='{.status.conditions}')
                components_status=$(echo $conditions_json | jq -r 'map(select(.type == "ComponentsReady"))[0].status')
                build_status=$(echo $conditions_json | jq -r 'map(select(.type == "BuildReady"))[0].status')
                srp_status=$(echo $conditions_json | jq -r 'map(select(.type == "SRPResourceSubmitted"))[0].status')
                ready_status=$(echo $conditions_json | jq -r 'map(select(.type == "Ready"))[0].status')
                loading_char=$(printf "%${counter}s")
                printf "ComponentsReady: $components_status; BuildReady: $build_status; SRPResourceSubmitted: $srp_status; Ready: $ready_status; ${loading_char// /.}\033[0K\r"
                counter=$((counter + 1))
                if [[ $counter -gt 3 ]]; then
                        counter=1
                fi
                sleep 2
        done

        if [[ $ready_status == 'False' ]]; then
                echo "Lever build $build_name failed"
                ready_message=$(echo $conditions_json | jq 'map(select(.type == "Ready"))[0].message')
                echo "Error: $ready_message"
                exit 1
        else
                echo "Lever build $build_name succeeded. Image published:"
                kubectl --kubeconfig <(printf "${LEVER_KUBECONFIG}") get request/$build_name -o jsonpath='{.status.artifactStatus.images[0].name}'
                echo ""
                kubectl --kubeconfig <(printf "${LEVER_KUBECONFIG}") get request/$build_name -o jsonpath='{.status.artifactStatus.images[0].image.tag}'
        fi
}

lever_build_request