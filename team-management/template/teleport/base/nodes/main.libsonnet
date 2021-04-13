local utility = import '../../../utility.libsonnet';
local kustomization_template = import 'kustomization.libsonnet';
local service_account_template = import 'serviceaccount.libsonnet';
local team_template = import 'team.libsonnet';
function(teams)
  utility.union_map(std.map(function(x) { [x + '.yaml']: team_template(x) }, teams)) + {
    'kustomization.yaml': kustomization_template(teams),
    'serviceaccount.yaml': service_account_template(teams),
  }
