{
  // union_map transforms
  // [
  //   { "a": "value a" },
  //   { "b": "value b" },
  // ]
  // into
  // {
  //   "a": "value a",
  //   "b": "value b",
  // }
  union_map(arr)::
    std.foldl(function(x, y) x + y, arr, {}),

  // prefix_file_names_array transforms
  // {
  //   "path/to/file1.yaml": "file 1 content in JSON",
  //   "path/to/file2.yaml": "file 2 content in JSON"
  // }
  // into
  // [
  //   { "prefix/path/to/file1.yaml": "file 1 content in JSON" },
  //   { "prefix/path/to/file2.yaml": "file 2 content in JSON" },
  // ]
  prefix_file_names_array(prefix, files)::
    std.objectValues(std.mapWithKey(function(x, y) { [prefix + '/' + x]: y }, files)),

  // prefix_file_names transforms
  // {
  //   "path/to/file1.yaml": "file 1 content in JSON",
  //   "path/to/file2.yaml": "file 2 content in JSON"
  // }
  // into
  // {
  //   "prefix/path/to/file1.yaml": "file 1 content in JSON",
  //   "prefix/path/to/file2.yaml": "file 2 content in JSON"
  // }
  prefix_file_names(prefix, files)::
    self.union_map(self.prefix_file_names_array(prefix, files)),

  // get_teams retrieves the array of teams from settings.
  get_teams(settings)::
    std.objectFields(settings.namespaces),

  // get_migrating_teams retrieves the array of migrating team from settings.
  get_migrating_teams(settings)::
    std.filter(function(x) std.count(settings.migrating_teams, x) > 0, self.get_teams(settings)),

  // get_team_namespaces retrieves the array of namespaces associated to a team.
  get_team_namespaces(settings, team)::
    std.objectFields(settings.namespaces[team]),

  // get_team_namespace_labels retrieves the labels for the namespace.
  get_team_namespace_labels(settings, team, namespace)::
    settings.namespaces[team][namespace],

  // get_tenants retrieves the array of tenants from settings.
  get_tenants(settings)::
    std.objectFields(settings.tenants),

  // get_all_namespaces retrieves the array of all namespaces associated to the tenant teams.
  get_all_namespaces(settings)::
    std.flattenArrays(std.map(function(x) self.get_team_namespaces(settings, x), self.get_teams(settings))),

  // get_allowed_namespaces retrieves the array of namespaces allowed to a team.
  get_allowed_namespaces(settings, team)::
    if std.objectHas(settings.allowed_namespaces, team) then settings.allowed_namespaces[team] else [],

  // get_all_allowed_namespaces retrieves the array of all namespaces allowed to the tenant teams.
  get_all_allowed_namespaces(settings)::
    std.flattenArrays(std.map(function(x) self.get_allowed_namespaces(settings, x), self.get_teams(settings))),

  // get_apps retrieves the array of tenant apps.
  get_apps(settings)::
    std.objectFields(settings.apps),

  // get_destination_apps retrieves the array of tenant apps for the specified destination.
  get_destination_apps(settings, destination)::
    std.filter(function(x) std.objectHas(self.get_app(settings, x).destinations, destination), self.get_apps(settings)),

  // get_app retrieves a tenant app settings.
  get_app(settings, name)::
    settings.apps[name],
}
