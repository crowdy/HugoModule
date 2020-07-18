<#
remove-module HugoModule; import-module HugoModule
#>
Function Edit-GitConfigure {
    code "$env:userprofile\.gitconfig"
}

Function New-ModuleFile {
<#
    .Logic
#>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string] $ModuleName = ${throw "no module name."}
    )

    $path = ($env:PSModulePath -split ';')[0]
    Set-Location $path
    mkdir $MoudleName
    Set-Location $MoudleName
    touch $($MoudleName).psm1
    git init
    code $($MoudleName).psm1
}

function Edit-dtc2admintool {
    $path = "$env:userprofile\Documents\WindowsPowerShell\Modules\dtc2admintool"
    code "$path"
}

function Edit-HugoModule {
    $path = "$env:userprofile\Documents\WindowsPowerShell\Modules\HugoModule"
    code "$path\HugoModule.psm1"
}

function New-HugoPost {
<#
.Logic
  - base path는 $env:userprofile
  - SiteName이 없으면 디폴트로 blog
  - prefix를 자동으로 달게 할 것.
  - prefix를 제외하고 타이틀이 같은 파일이 있으면 그 파일을 열 것.
#>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string] $title = ${throw "no title give."},
        [string] $SiteName = 'blog'
    )

    Set-Location $env:userprofile\$SiteName

    if ($title.Contains("/")) {
        $index = $title.IndexOf('/')
        $path, $filename = ($title[0..$index] -join ""), ($title[$($index+1)..$($title.length-1)] -join "")
        Write-Debug $path

        $file = Get-ChildItem "content/ko/$path" -Filter "???? *$filename.md"
        if ($file) {
            Write-Debug $file
            code $file.FullName
            return
        }

        $files = get-childitem "content/ko/$path" -Filter "???? *"
        if ($files) {
            $prefix_num = [int](($files.Name | Select-Object -last 1)[1..3] -join "") + 1
        } else {
            $prefix_num = 1
        }

        if ($title.StartsWith("hyper-v")) {
            $prefix_char = "c"
        } else {
            $prefix_char = $title[0]
        }

        Write-Debug $prefix_num
        $title = "$path$($prefix_char){0:d3} $filename" -f $prefix_num
    }

    if (! $title.EndsWith(".md")) {
        $title += ".md"
    }
    Write-Debug "hugo new ./content/ko/$title"
    hugo new ./content/ko/$title
}