<#
## Installation
$targetpath = "$env:userprofile\Documents\WindowsPowerShell\Modules\HugoModule"
if (! (test-path $targetpath)) { mkdir $targetpath -force }
copy C:\Users\usr0100023\blog\projects\HugoModule\HugoModule.psm1 $targetpath
dir $targetpath
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

function Edit-HugoModule {
    $path = "$env:userprofile\Documents\WindowsPowerShell\Modules\HugoModule"
    code "$path\HugoModule.psm1"
}

Function New-HugoPost {
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

        $file = Get-ChildItem "content/ko/$path" -Filter "*$filename.md"
        if ($file) {
            Write-Debug $file
            code $file.FullName
            return
        }

        $files = get-childitem "content/ko/$path" | Where-Object { !( $_ | Select-String "dashboard" -quiet) }
        if ($files) {
            $prefix_word = ($files.Name | Select-Object -last 1).Split(" ")[0]
            $prefix_num = [int]($prefix_word.Substring($prefix_word.Length - 2)) + 1
        } else {
            $prefix_num = 1
        }

        Write-Host "title : $title"

        if ($title.StartsWith("hyper-v")) {
            $prefix_char = "hyperv"
        } elseif ($title.StartsWith("bow")) { 
            $prefix_char = "bow"
        } elseif ($title.StartsWith("carme")) { 
            $prefix_char = "carme"
        } elseif ($title.StartsWith("conoha")) { 
            $prefix_char = "conoha"
        } elseif ($title.StartsWith("dc2")) { 
            $prefix_char = "dc2"
        } elseif ($title.StartsWith("gmo")) { 
            $prefix_char = "gmo"
        } elseif ($title.StartsWith("kvm")) { 
            $prefix_char = "kvm"
        } else {
            $prefix_char = [Char]::ToLower($title[0])
        }

        Write-Debug "prefix num is $prefix_num"
        $title = "$path$($prefix_char){0:d3} $filename" -f $prefix_num
    }

    if (! $title.EndsWith(".md")) {
        $title += ".md"
    }
    Write-Debug "hugo new ./content/ko/$title"
    hugo new ./content/ko/$title
}


Function Get-HugoPost {
    [CmdletBinding()]
    param(
        [string] $SiteName = 'blog'
    )

    Set-Location $env:userprofile\$SiteName\content\ko

    $files = Get-ChildItem -Path $env:userprofile\$SiteName\content\ko -Include *.md -Recurse
    
    # $files.Count
    # $files | ft -Property DirectoryName, Name
    
    $posts = [System.Collections.ArrayList]@()
    
    Foreach($f in $files) {

        if ($f.Name.StartsWith('_')) {
            Continue
        }
    
        $post = @{}
        $post['DirectoryName'] = $f.DirectoryName
        $post['Name'] = $f.Name
    
        $content = Get-Content $f -Encoding UTF8
        $frontmatter = ""
        $delimeter = $content[0]
        if ($delimeter -notin @("---", "+++")) {
            Write-Host "no delimeter found."
            Write-Host $post.Name
            Continue
        }
    
        $index = 1
        $IN_FONTMATTER = $true
    
        $frontmatter = ""
        $post['Content'] = ""
        While($index -lt $content.Length) {
            $line = $content[$index]
    
            if ($IN_FONTMATTER) {
                $frontmatter += $line + "`n"
            } else {
                $post['Content'] += $line + "`n"
            }
            
            if ($line -eq $delimeter) {
                # add frontmatter
                $IN_FONTMATTER = $false
                try {
                    $post['FrontMatter'] = (ConvertFrom-Yaml $frontmatter)
                } catch {
                    Write-Host $_
                    Write-Host $post.DirectoryName
                    Write-Host $post.Name
                    Write-Host $frontmatter
                }
            }
            $index++
        }
    
        [void]$posts.Add($post)
    }
    
    return $posts
}


Function Get-HugoReport {
    [CmdletBinding()]
    param(
        [switch] $DraftOnly,
        [switch] $PublishedOnly,
        [switch] $Ascending
    )

    Write-Host -ForegroundColor Red "objective: 1000 chars"
    Write-Host -ForegroundColor Red "objective: 3 published posts per a day"
    Write-Host -ForegroundColor Red "objective: 40 mins per a post"

    $posts = get-hugopost
    $report = [System.Collections.ArrayList]@()
    foreach ($p in $posts) {
        $total_line += $p.Content.Split("`n").Count
        $r = [PSCustomObject]@{
            Date = $p.FrontMatter.Date
            LineCount = $p.Content.Split("`n").Count
            CharCount = $p.Content.ToCharArray().Count
            FileCode = $p.Name.SubString(0, 4)
            Draft = $p.FrontMatter.Draft
        }
        [void]$report.Add($r)
    }

    $report = $report | Where-Object {[char]::IsDigit($_.FileCode.SubString(1,1))}
    if ($DraftOnly) {
        $report = $report | Where-Object {$_.Draft}
    } elseif ($PublishedOnly) {
        $report = $report | Where-Object {! $_.Draft}
    }

    if ($Ascending) {
        $report = $report | Sort-Object -Property LineCount
    }
    else  {
        $report = $report | Sort-Object -Property LineCount -Descending
    }

    return $report
}


Function Invoke-Repeatedly {
    [CmdletBinding()]
    Param(
        [int] $Second = 5 * 60,
        $ScriptBlock,
        $ArgumentList
    )

    While($True) {
        Get-Date
        & $ScriptBlock -ArgumentList $ArgumentList
        Start-Sleep -s $Second
    }
}

function lsltr { Get-ChildItem | Sort-Object LastAccessTime | Format-Table }
Set-Alias -Name watch Invoke-Repeatedly

<#

$res = Get-hugoreport
$res | where {$_.FileCode -like "p*"} | ft
$res | where {$_.FileCode.StartsWith("p")} | ft
$res | where {$_.FileCode.StartsWith("p")} | sort -property draft | ft
$res | where {$_.FileCode.StartsWith("p") -And (! $_.Draft)} | ft

$res | where {$_.FileCode.StartsWith("v") -And (! $_.Draft)} | ft
#>

function hvd {
    Write-Host "Hugo VSCode Draft"
    get-hugoreport | Where-Object {$_.FileCode.StartsWith("v") -And ($_.Draft)} | Format-Table
}

function hvnd {
    Write-Host "Hugo VSCode Not Draft"
    get-hugoreport | Where-Object {$_.FileCode.StartsWith("v") -And (! $_.Draft)} | fFormat-Tablet
}

function hhd {
    Write-Host "Hugo Hugo Draft"
    get-hugoreport | Where-Object {$_.FileCode.StartsWith("h") -And ($_.Draft)} | Format-Table
}

function hhnd {
    Write-Host "Hugo Hugo Not Draft"
    get-hugoreport | Where-Object {$_.FileCode.StartsWith("h") -And (! $_.Draft)} | Format-Table
}

function hpd {
    Write-Host "Hugo Powershell Draft"
    get-hugoreport | Where-Object {$_.FileCode.StartsWith("p") -And ($_.Draft)} | Format-Table
}

function hpnd {
    Write-Host "Hugo Powershell Not Draft"
    get-hugoreport | Where-Object {$_.FileCode.StartsWith("p") -And (! $_.Draft)} | Format-Table
}

function hdd {
    Write-Host "Hugo DevNote Draft"
    get-hugoreport | Where-Object {$_.FileCode.StartsWith("d") -And ($_.Draft)} | Format-Table
}

function hdnd {
    Write-Host "Hugo DevNote Not Draft"
    get-hugoreport | Where-Object {$_.FileCode.StartsWith("d") -And (! $_.Draft)} | Format-Table
}

 function hcd {
     Write-Host "Hugo Code Draft"
     get-hugoreport | Where-Object {$_.FileCode.StartsWith("c") -And (! $_.Draft)} | Format-Table
 }
 function hcnd {
     Write-Host "Hugo Code Not Draft"
     get-hugoreport | Where-Object {$_.FileCode.StartsWith("c") -And (! $_.Draft)} | Format-Table
 }