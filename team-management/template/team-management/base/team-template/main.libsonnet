local utility = import '../../../utility.libsonnet';
local elastic_template = import 'elastic-serviceaccount.libsonnet';
local kustomization_template = import 'kustomization.libsonnet';
local namespace_template = import 'namespace.libsonnet';
local project_template = import 'project.libsonnet';
function(settings, team)
  local namespaces = utility.get_team_namespaces(settings, team);
  local allowed_namespaces = utility.get_allowed_namespaces(settings, team);
  local all_teams_namespaces = utility.get_all_namespaces(settings);
  local all_allowed_namespaces = utility.get_all_allowed_namespaces(settings);
  {
    'elastic-serviceaccount.yaml': elastic_template(namespaces),
    'kustomization.yaml': kustomization_template(team, namespaces),
    'project.yaml': if team == 'maneki' then project_template(team, std.uniq(all_teams_namespaces + all_allowed_namespaces)) else project_template(team, std.uniq(namespaces + allowed_namespaces)),
  } + std.foldl(function(x, y) x { [y + '.yaml']: namespace_template(settings, team, y) }, namespaces, {})
