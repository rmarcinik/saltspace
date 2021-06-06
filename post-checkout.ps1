$Path='minion'
$Value="
file_roots:
  base:
    - $PWD
"
$Content = Get-Content -Path "salt/minion"
$Value = $Content + $Value.replace('\','/')
Set-Content -Value $Value -Path $Path