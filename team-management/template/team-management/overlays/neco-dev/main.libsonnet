local utility = import '../../../utility.libsonnet';
local kustomization_template = import 'kustomization.libsonnet';
local project_template = import 'project.libsonnet';
local get_project_files = function(team)
  std.foldl(function(x, y) x { ['project-' + team + '.yaml']: project_template(team) }, team, {});
function(settings)
  local project_files = std.map(function(team) get_project_files(team), std.objectFields(settings.repositories));
  utility.union_map([{
    'kustomization.yaml': kustomization_template(settings.repositories),
  }] + project_files)
