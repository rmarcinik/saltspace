#!pyobjects
'''
  This is the first step to the local salt environment
  creating the directory structure and setting the salt config file
  file_roots is important for directing salt to sls files

  this depends on a config key "workspace" that will act as the root directory

  download git projects at workspace:projects

  link the project files into the salt tree
'''
import os
import re

def norm (*paths):
  return os.path.join(*paths).replace(os.sep, '/')

pattern = re.compile(":(\w+\/\w+)\.git")
def split_repo(path):
  '''
    This should return two names, one for the "group" and one for repo itself
  '''
  match,*_ = pattern.findall(path)
  return match.split('/')

workspace = pillar('workspace:dir')
saltpath = pillar('workspace:saltpath')
gitpath = pillar('workspace:gitpath')
url = pillar('workspace:url')

statespath = pillar('workspace:statespath')
pillarpath = pillar('workspace:pillarpath')

File.directory(
  'create salt dir',
  name=saltpath,
  win_owner=grains('username'),
  makedirs=True,
)

File.directory(
  'create config dir',
  name=norm(saltpath, 'conf'),
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
  name=pillarpath,
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
  name=norm(saltpath, 'minion'),
  dataset={
    'ipc_mode': 'tcp',
    'file_client': 'local',
    'state_verbose': False,
    'default_include': 'conf/*.conf',
    'file_roots': {'base': [statespath]},
    'pillar_roots': {'base': [pillarpath]},
    'workspace': pillar('workspace'),
  },
  formatter='yaml'
)

includes = []

for repo, enabled in pillar('workspace:repos', {}).items():

  group, name = split_repo(repo)
  target = norm(gitpath, name)
  Git.latest(
    f"deploy {repo}",
    name=repo,
    target=target,
    identity=pillar('workspace:sshkey'),
    force_reset='remote-changes',
  )

  File.symlink(
    f"link {repo} to states dir",
    name=norm(statespath, name),
    target=norm(target, 'states'),
    makedirs=True
  )
  File.symlink(
    f"link {repo} to pillar dir",
    name=norm(pillarpath, name),
    target=norm(target, 'pillar'),
    makedirs=True
  )

  includes.append(name)


File.serialize(
  'create pillar top',
  name=norm(pillarpath, 'top.sls'),
  dataset={'base': {grains('id'):includes}},
  formatter='yaml'
)

File.serialize(
  'create states top',
  name=norm(statespath, 'top.sls'),
  dataset={'base': {grains('id'):includes}},
  formatter='yaml'
)