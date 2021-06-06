<#
run ps1 files with a git hook:
.\.git\hooks\post-checkout

#!C:/Program\ Files/Git/usr/bin/sh.exe
echo
exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\post-checkout.ps1"
exit

#>
$Base = 'minion'
$Custom = 'me.conf'

$File_root = "$PWD".replace('\','/')
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
    - $File_root/pillar"

Set-Variable -Name $Custom -Value "# Custom config for the workspace deployment
#
#  dir: the location to create a salt and git directory
#  url: a remote git host to pull projects from
#  sshkey: the private key that has been set up to reach the git host
#  projects: these are the subpaths in the git instance, True will download and link the repo
#    rmarcinik/Redball: True
#    rmarcinik/saltspace: True

workspace:
  dir: C:/Users/rigel/workspace
  url: github.com
  sshkey: C:/Users/rigel/.ssh/github
  projects:
    rmarcinik:
      saltspace: True
      local: True"

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

set-config -Path $Base
