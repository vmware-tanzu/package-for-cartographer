set -o errexit
set -o nounset
set -o pipefail

readonly root=$(cd $(dirname $0)/.. && pwd)
readonly scratch=$(mktemp -d)

main() {
        cd $root/tests

        show_vars
        setup
        check_permissions
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
}

check_permissions() {
        local sa=app-viewer

        _assert app-viewer get workload
        _assert app-editor create workload
        _assert app-viewer-cluster-access get clusterdeliveries
        _assert app-operator-cluster-access create clusterdeliveries
}

_assert() {
        local who=$1
        local verb=$2
        local resource=$3

        if [[ "$(_can_it $who $verb $resource)" == "$who" ]]; then
                echo "GOOD! $who can $verb $resource"
                return 0
        fi

        echo "FAIL. $who should $verb $resource but can't."
        exit 1
}

_can_it() {
        local who=$1
        local verb=$2
        local resource=$3

        kubectl-who-can $verb $resource -o json |
                jq -r '.roleBindings[].name' |
                grep "^${who}$"
}

main "$@"
