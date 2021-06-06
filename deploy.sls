#!pyobjects
'''
  This is the first step to the local salt environment
  creating the directory structure and setting the salt config file
  file_roots is important for directing salt to sls files

  this depends on a config key "workspace" that will act as the root directory

  download git projects at workspace:projects

  link the project files into the salt tree
'''

from os.path import join

workspace = config('workspace:dir')
saltpath = join(workspace, 'salt')
gitpath = join(workspace, 'git')
url = config('workspace:url')

File.directory(
  'create salt dir',
  name=join(saltpath),
  win_owner=grains('username'),
  makedirs=True,
)

File.directory(
  'create config dir',
  name=join(saltpath, 'conf'),
  win_owner=grains('username'),
  makedirs=True,
)
statespath = join(saltpath, 'states')
File.directory(
  'create states dir',
  name=statespath,
  win_owner=grains('username'),
  makedirs=True,
)

File.directory(
  'create pillar dir',
  name=join(saltpath, 'pillar'),
  win_owner=grains('username'),
  makedirs=True,
)

Environ.setenv(
  'add workspace variable',
  name = 'workspace',
  value = workspace,
  permanent = 'HKLM',
)


File.serialize(
  'create local base config',
  name=join(saltpath, 'minion'),
  dataset={
    'ipc_mode': 'tcp',
    'file_client': 'local',
    'state_verbose': False,
    'default_include': 'conf/*.conf',
    'file_roots': {'base': [statespath]},
  },
  formatter='yaml'
)

for repo, enabled in config('workspace:projects', {}).items():
  if enabled:

    target = join(gitpath, repo)
    Git.latest(
      f"deploy {repo}",
      name=f"git@{url}:/{repo}.git",
      target=target,
      identity=config('workspace:sshkey'),
      force_reset='remote-changes',
    )

    File.symlink(
      f"link {repo} to states dir",
      name=join(statespath, repo),
      target=target,
      makedirs=True
    )