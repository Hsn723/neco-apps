local utility = import '../../../utility.libsonnet';
local kustomization_template = import 'kustomization.libsonnet';
local project_template = import 'project.libsonnet';
local tenant_template = import 'tenant.libsonnet';
local get_project_files = function(team)
  std.foldl(function(x, y) x { ['project-' + team + '.yaml']: project_template(team) }, team, {});
local get_tenant_files = function(settings, tenant)
  std.foldl(function(x, y) x { ['tenant-' + tenant + '.yaml']: tenant_template(tenant) }, tenant, {});
function(settings)
  local tenants = utility.get_tenants(settings);
  local project_files = std.map(function(team) get_project_files(team), std.objectFields(settings.repositories));
  local tenant_files = std.map(function(tenant) get_tenant_files(settings, tenant), tenants);
  utility.union_map([{
    'kustomization.yaml': kustomization_template(settings.repositories, tenants),
  }] + project_files + tenant_files)
