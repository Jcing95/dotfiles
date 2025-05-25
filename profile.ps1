Invoke-Expression (&starship init powershell)

function ws {
    Set-Location 'D:\workspace'
}

$PSStyle.FileInfo.Directory = "`e[48;2;21;56;16m"

Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

