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


Function Show-HugoReport {

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
    $report |where {[char]::IsDigit($_.FileCode.SubString(1,1))} | sort -Property LineCount -Descending | ft

    Write-Host -ForegroundColor Red "objective: 1000 chars"
    Write-Host -ForegroundColor Red "objective: 3 published posts per a day"
    Write-Host -ForegroundColor Red "objective: 40 mins per a post"
}
