# Package for Cartographer

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Overview](#overview)
- [Pre-requisites](#pre-requisites)
- [Installation](#installation)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Overview

[carvel]-based Packaging of [Cartographer].


## Pre-requisites

- [kapp-controller]
- [Tanzu CLI]
- [cert-manager]


## Installation

0. Submit the Package and PackageMetadata objects to the cluster


```bash
kubectl apply \
  -f https://github.com/vmware-tanzu/package-for-cartographer/releases/download/v0.0.0/package.yaml
  -f https://github.com/vmware-tanzu/package-for-cartographer/releases/download/v0.0.0/package-metadata.yaml
```
```console
packagemetadata.data.packaging.carvel.dev/cartographer.community.tanzu.vmware.com created
package.data.packaging.carvel.dev/cartographer.community.tanzu.vmware.com.0.0.0 created
```

1. Install the package

```bash
tanzu package install cartographer \
  --package-name cartographer.community.tanzu.vmware.com \
  --version 0.0.0
```
```console
\ Installing package 'cartographer.community.tanzu.vmware.com'
| Getting package metadata for 'cartographer.community.tanzu.vmware.com'
| Creating service account 'cartographer-default-sa'
| Creating cluster admin role 'cartographer-default-cluster-role'
| Creating cluster role binding 'cartographer-default-cluster-rolebinding'
| Creating package resource
/ Waiting for 'PackageInstall' reconciliation for 'cartographer'
\ 'PackageInstall' resource install status: Reconciling


 Added installed package 'cartographer'
```

Once installed, the following objects can be found in the cluster:

```bash
kapp inspect -a cartographer-ctrl
```
```console
Resources in app 'cartographer-ctrl'

Namespace            Name                                     Kind
(cluster)            cartographer-cluster-admin               ClusterRoleBinding
^                    cartographer-controller-admin            ClusterRole
^                    cartographer-system                      Namespace
^                    cartographer-user-admin                  ClusterRole
^                    cartographer-user-view                   ClusterRole
^                    clusterconfigtemplates.carto.run         CustomResourceDefinition
^                    clusterdeliveries.carto.run              CustomResourceDefinition
^                    clusterdeploymenttemplates.carto.run     CustomResourceDefinition
^                    clusterimagetemplates.carto.run          CustomResourceDefinition
^                    clusterruntemplates.carto.run            CustomResourceDefinition
^                    clustersourcetemplates.carto.run         CustomResourceDefinition
^                    clustersupplychains.carto.run            CustomResourceDefinition
^                    clustersupplychainvalidator              ValidatingWebhookConfiguration
^                    clustertemplates.carto.run               CustomResourceDefinition
^                    deliverables.carto.run                   CustomResourceDefinition
^                    deliveryvalidator                        ValidatingWebhookConfiguration
^                    runnables.carto.run                      CustomResourceDefinition
^                    workloads.carto.run                      CustomResourceDefinition
cartographer-system  cartographer-controller                  Deployment
^                    cartographer-controller                  ServiceAccount
^                    cartographer-controller-f574b6649        ReplicaSet
^                    cartographer-controller-f574b6649-54zz2  Pod
^                    cartographer-webhook                     Certificate
^                    cartographer-webhook                     Endpoints
^                    cartographer-webhook                     Secret
^                    cartographer-webhook                     Service
^                    cartographer-webhook-j4cdt               EndpointSlice
^                    cartographer-webhook-n6z2r               CertificateRequest
^                    private-registry-credentials             Secret
^
```


## Documentation

This repository is solely concerned with the Packaging of Cartographer to be
installed in a Kubernetes clusters making use of Carvel Packaging primitives.

For documentation specific to Cartographer, check out
[cartographer.sh](https://cartographer.sh) and the main repository
[vmware-tanzu/cartographer](https://github.com/vmware-tanzu/cartographer).


## Contributing

See [./CONTRIBUTING.md](./CONTRIBUTING.md).


## License

See [./LICENSE](./LICENSE).


[carvel]: https://carvel.dev/
[Cartographer]: https://cartographer.sh
[kapp-controller]: https://github.com/vmware-tanzu/carvel-kapp-controller
[Tanzu CLI]: https://github.com/vmware-tanzu/tanzu-framework
[cert-manager]: https://github.com/cert-manager/cert-manager

