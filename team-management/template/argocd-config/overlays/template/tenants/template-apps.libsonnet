function(name, repo, destination, revision) [{
  apiVersion: 'argoproj.io/v1alpha1',
  kind: 'Application',
  metadata: {
    name: name,
    namespace: 'argocd',
    labels: {
      'is-tenant': 'true',
    },
    annotations: {
      'argocd.argoproj.io/sync-wave': '9',
    },
  },
  spec: {
    project: 'tenant-app-of-apps',
    source: {
      repoURL: repo,
      targetRevision: revision,
      path: 'argocd-config/overlays/' + destination,
    },
    destination: {
      server: 'https://kubernetes.default.svc',
      namespace: 'argocd',
    },
    syncPolicy: {
      automated: {
        prune: true,
      },
    },
  },
}]
