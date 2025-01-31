function(teams) [{
  apiVersion: 'kustomize.config.k8s.io/v1beta1',
  kind: 'Kustomization',
  resources: std.set(
    ['clusterrolebinding.yaml', 'serviceaccount.yaml'] +
    std.map(function(x) x + '.yaml', teams)
  ),
  images: [
    {
      name: 'quay.io/cybozu/teleport-node',
      newTag: '8.3.6.2',
    },
  ],
}]
