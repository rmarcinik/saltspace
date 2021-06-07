#!py

def run():
  import os
  def norm (*paths):
    return os.path.join(*paths).replace(os.sep, '/')
  user = os.environ['USERPROFILE']
  workspace = norm(user, 'workspace')
  sshkey = norm(user, '.ssh', 'github')
  gitpath = norm(workspace, 'git')
  saltpath = norm(workspace, 'salt')
  statespath = norm(saltpath, 'states')
  pillarpath = norm(saltpath, 'pillar')

  return {
    'workspace': {
      'dir': workspace,
      'url': 'github.com',
      'sshkey': sshkey,
      'projects': {
        'rmarcinik': {
          'local': True,
          'saltspace': True,
        },
      },
      'gitpath': gitpath,
      'saltpath': saltpath,
      'statespath': statespath,
      'pillarpath': pillarpath,
    }
  }
