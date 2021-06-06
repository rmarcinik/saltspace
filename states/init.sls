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

workspace = pillar('workspace:dir')
saltpath = join(workspace, 'salt')
gitpath = join(workspace, 'git')
url = pillar('workspace:url')

statespath = join(saltpath, 'states')
pillarpath = join(saltpath, 'pillar')

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
  name = 'WORKSPACE',
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
    'pillar_roots': {'base': [pillarpath]},
  },
  formatter='yaml'
)

includes = []

for group, projects in pillar('workspace:projects', {}).items():
  for repo, enabled in projects.items():
    if enabled:

      Git.latest(
        f"deploy {repo}",
        name=f"git@{url}:{group}/{repo}.git",
        target=join(gitpath, repo),
        identity=pillar('workspace:sshkey'),
        force_reset='remote-changes',
      )

      File.symlink(
        f"link {repo} to states dir",
        name=join(statespath, repo),
        target=join(gitpath, repo, 'states'),
        makedirs=True
      )
      File.symlink(
        f"link {repo} to pillar dir",
        name=join(pillarpath, repo),
        target=join(gitpath, repo, 'pillar'),
        makedirs=True
      )

      includes.append(repo)


File.serialize(
  'create pillar top',
  name=join(pillarpath, 'top.sls'),
  dataset={'base': {grains('id'):includes}},
  formatter='yaml'
)

File.serialize(
  'create states top',
  name=join(statespath, 'top.sls'),
  dataset={'base': {grains('id'):includes}},
  formatter='yaml'
)