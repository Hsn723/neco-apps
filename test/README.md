How to run tests
================

dctest
------

1. Set `NECO_DIR` environment variable to point the directory for `github.com/cybozu-go/neco`
2. Place `account.json` file for GCP Cloud DNS in this directory.
3. Place `cybozu_private_repo_read_pat` file for reading private repository in this directory.

    ```console
    PAT=$(systemd-ask-password -)
    echo $PAT > /path/to/neco-apps/test/cybozu_private_repo_read_pat
    ```

4. Push the current feature branch to GitHub.
5. Prepare dctest environment using `github.com/cybozu-go/neco/dctest`.

    ```console
    # In this case, menu-ss.yml should be used.
    make -C ${NECO_DIR} clean
    make -C ${NECO_DIR}/dctest setup
    make -C ${NECO_DIR}/dctest placemat MENU_ARG=menu-ss.yml
    make -C ${NECO_DIR}/dctest test SUITE=bootstrap
    ```

6. Run following commands to setup tools.

    ```console
    cd test
    make setup
    ```

7. Run either one of the following.

    1. Setup all applications without tests.

        ```console
        make dctest
        ```

    2. Run all tests.

        ```console
        make test
        make dctest SUITE=prepare
        make dctest SUITE=run
        ```

`./account.json`
----------------

External DNS in Argo CD app `external-dns` requires Google Application Credentials in JSON file.
neco-apps test runs `kubectl create secrets .... --from-file=account.json` to register `Secret` for External DNS.
To run `external-dns` test, put your account.json of the Google Cloud service account which has a role `roles/dns.admin`.
See details of the role at https://cloud.google.com/iam/docs/understanding-roles#dns-roles

`./cybozu_private_repo_read_pat`
--------------------------------

The PAT in this file is required for neco-apps checkout and for ArgoCD to read the private repository.
neco-apps test runs `argocd repocreds add https://github.com/cybozu-private/ --username cybozu-neco --password=<cybozu_private_repo_read_pat>`.
This PAT must belong to a `cybozu-neco` user.

Using `argocd`
--------------

`argocd` is a command-line tool to manage Argo CD apps.

Following features are most useful:

- `argocd app list`: list apps and their statuses.
- `argocd app get NAME`: show detailed information of an app.
- `argocd app sync NAME`: immediately synchronize an app with Git repository.

Makefile
--------

You can run test for neco-apps on the running dctest.

- `make setup`: Install test required components.
- `make clean`: Delete generated files.
- `make code-check`: Run `gofmt` and other trivial tests.
- `make validation`: Run validation test of manifests.
- `make test-alert-rules`: Run unit test of Prometheus alerts.
- `make test`: Run all static tests.

Ignore the status of tenants' Applications
------------------------------------------
If you would like to ignore the sync status, label `is-tenant="true"` to the App.
