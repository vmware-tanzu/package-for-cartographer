set -o errexit
set -o nounset
set -o pipefail

readonly root=$(cd $(dirname $0)/.. && pwd)
readonly scratch=$(mktemp -d)

main() {
        cd $root/tests

        show_vars
        setup
        test_app_viewer
}

show_vars() {
        echo "
        scratch:        $scratch
        "
}

setup() {
        local name=aggregated-roles

        kapp deploy --yes -a $name -f ./02-$name.yaml
        # trap "kapp delete -a $name --yes" EXIT

        # wait for the tokens
}

test_app_viewer() {
        local sa=app-viewer

        _prepare_kubeconfig $sa

        export KUBECONFIG=$scratch/$sa
        kubectl auth can-i get workload
        kubectl auth can-i create workload
        kubectl auth can-i delete workload
}

_prepare_kubeconfig() {
        local sa=$1
        local user=kind-kind
        local original_kubeconfig=~/.kube/config
        local kubeconfig=$scratch/$sa

        local token
        token=$(_get_token $sa)

        cp $original_kubeconfig $kubeconfig

        KUBECONFIG=$kubeconfig \
                kubectl config set-credentials \
                        $user --token=$token
}

_get_token() {
        local sa=$1

        local token_base64
        token_base64=$(kubectl get secret $sa -o jsonpath={.data.token})

        printf $token_base64 | base64 --decode
}


main "$@"

