<#
run ps1 files with a git hook:
.\.git\hooks\post-checkout

#!C:/Program\ Files/Git/usr/bin/sh.exe
echo
exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\post-checkout.ps1"
exit

#>
function norm ($Parent, $Child) {
    # normalize the path with forward slashes for consistency
    $path = Join-Path -Path $Parent -ChildPath $Child
    $path.replace('\','/')
}

function set-config ($Path) {
    $Value = Get-Variable -Name $Path -ValueOnly
    $Correct=$FALSE

    if(Test-Path $Path) {
        $Content = Get-Content -Path $Path -Raw
        $Correct = $Content -eq $Value
    }
    if(!$Correct) {
        Set-Content -Value $Value -Path $Path -NoNewline
        $Content = Get-Content -Path $Path -Raw
        $Correct = $Content -eq $Value
    }
    $Correct
}

$Base = 'minion'
$Custom = 'pillar/init.sls'
$userprofile = $env:USERPROFILE
$sshkey = norm $userprofile '.ssh\github'

#The root of the new workspace, where git files and other work will reside
$workspace = norm $userprofile 'workspace'

# The start of the workspace has a directory to store git repos
# The salt directory will be configured for a local salt-minion
$gitpath = norm $Workspace 'git'
$saltpath = norm $Workspace 'salt'

# Inside the salt path there are paths to store state and pillar files
# This config will point to these and salt-call will use the local files to operate
$statespath = norm $saltpath 'states'
$pillarpath = norm $saltpath 'pillar'

Set-Variable -Name $Base -Value "ipc_mode: tcp
log_level: debug
file_client: local
state_verbose: True
default_include: 'config/*.conf'

file_roots:
  base:
    - $statespath
pillar_roots:
  base:
    - $pillarpath"

Set-Variable -Name $Custom -Value "workspace:
  dir: $workspace
  sshkey: $sshkey
  repos:
    git@github.com:rmarcinik/local.git: True
    git@github.com:rmarcinik/saltspace.git: True

  gitpath: $gitpath
  saltpath: $saltpath
  statespath: $statespath
  pillarpath: $pillarpath"


set-config -Path $Base
set-config -Path $Custom
