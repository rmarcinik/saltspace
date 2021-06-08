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
        $Path = Get-Folder
        Set-Content -Value $Value -Path $Path -NoNewline
        $Content = Get-Content -Path $Path -Raw
        $Correct = $Content -eq $Value
    }
    $Correct
}

$Base = 'minion'
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
default_include: '*.conf'

file_roots:
  base:
    - $File_root/states
pillar_roots:
  base:
    - $File_root/pillar

workspace:
  dir: $workspace
  url: github.com
  sshkey: $sshkey
  projects:
    rmarcinik:
      saltspace: True
      local: True

  gitpath: $gitpath
  saltpath: $saltpath
  statespath: $statespath
  pillarpath: $pillarpath"


set-config -Path $Base
