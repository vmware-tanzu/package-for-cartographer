/release

  /cartographer
    - cartographer-bundle.tar |
    - metadata.yaml           |
    - package.yaml            | bundle.sh
    - README.yaml             |
    - cartographer.tgz    (everything relocated, good to go)  | release.sh
        -- relocates to the proper container image registries
        -- creates the final .tgz



Assets:

cartographer-bundle.tar
cartographer-catalog-bundle.tar

- cartographer-catalog.tgz
  - package.yaml
  - metadata.yaml

- cartographer-catalog-tce.tgz
  - package.yaml    // generated with `community.tanzu.vmware.com`
  - metadata.yaml

- cartographer.tgz
  - package.yaml
  - metadata.yaml

- cartographer-tce.tgz
  - package.yaml    // generated with `community.tanzu.vmware.com`
  - metadata.yaml
