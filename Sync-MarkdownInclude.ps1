#Requires -Version 6
$sb = [System.Text.StringBuilder]::new()
class IncludeOptions {
    [string]$head
    [string]$foot
    [int]$from
    [int]$to
    [string]$filePath
    [string]$full
    [string]$asType
    [string]$basePath
    [string]$lang
    [bool]$isIncludeBlock
}
function Get-DefaultAsType ([string]$asType) {
    switch ($asType) {
        "code" { return "code" }
        Default { return "raw" }
    }
}
function Get-DefaultFromNumber ([string]$number) {
    if ([string]::IsNullOrWhiteSpace($number)) {
        return 0
    }
    return [int32]::Parse($number) - 1
}
function Get-DefaultToNumber ([string]$number) {
    if ([string]::IsNullOrWhiteSpace($number)) {
        return -1
    }
    return [int32]::Parse($number) - 1
}
function Invoke-RenderString ([IncludeOptions]$options) {
    $file = [System.IO.FileInfo]::new([System.IO.Path]::Join($options.basePath, $options.filePath))
    $content = Get-Content $file.FullName -Raw
    if ($options.from -ne 0 -or $options.to -ne -1) {
        $lines = $content.Split([System.Environment]::NewLine)
        $to = $options.to
        $from = $options.from
        if ($to -gt $lines.Length -or $to -eq -1) {
            $to = $lines.Count - 1
        }
        if ($from -gt $lines.Length) {
            $from = $lines.Count - 1
        }
        if ($from -gt $to) {
            if ($options.isIncludeBlock) {
                return $options.full
            }
            else {
                return [string]::Empty
            }
        }
        if ($from -ne 0 -or $to -ne -1) {
            $content = [string]::Join([System.Environment]::NewLine, $lines[$from..$to])
        }
    }
    $includeBlocks = [regex]::Matches($content, "(?is)(?<head>\<!--+ {0,}#md_include +`"(?<path>.+?)`"(?: +from +(?<from>\d+)(?: +to +(?<to>\d+))?)?(?: +as +(?<as>\w+))?(?: +lang +(?<lang>\w+))? {0,}-+\>).+?(?<foot><!--+ {0,}#md_include end +-+-\>)")
    foreach ($includeBlock in $includeBlocks) {
        [IncludeOptions]$nextOptions = @{
            head           = $includeBlock.Groups["head"].Value
            foot           = $includeBlock.Groups["foot"].Value
            filePath       = $includeBlock.Groups["path"].Value
            asType         = Get-DefaultAsType($includeBlock.Groups["as"].Value)
            from           = Get-DefaultFromNumber($includeBlock.Groups["from"].Value)
            to             = Get-DefaultToNumber($includeBlock.Groups["to"].Value)
            basePath       = $file.DirectoryName
            full           = $includeBlock.Groups["0"].Value
            lang           = $includeBlock.Groups["lang"].Value
            isIncludeBlock = $false
        }
        $new = Invoke-RenderString($nextOptions)
        $content = $content.Replace($includeBlock.Groups["0"].Value, $new)
    }
    switch ($options.asType) {
        "code" { 
            [void]$sb.Clear()
            [void]$sb.AppendLine("``````$($options.lang)")
            [void]$sb.AppendLine($content)
            [void]$sb.Append("``````")
            $content = $sb.ToString()
            break
        }
        Default { break }
    }
    if ($options.isIncludeBlock) {
        [void]$sb.Clear()
        [void]$sb.AppendLine($options.head)
        [void]$sb.AppendLine($content)
        [void]$sb.Append($options.foot)
        $content = $sb.ToString()
    }
    return $content
}
$files = Get-ChildItem -Recurse *.md
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $includeBlocks = [regex]::Matches($content, "(?is)(?<head>\<!--+ {0,}#md_include +`"(?<path>.+?)`"(?: +from +(?<from>\d+)(?: +to +(?<to>\d+)))?(?: +as +(?<as>\w+))?(?: +lang +(?<lang>\w+))? {0,}-+\>).+?(?<foot><!--+ {0,}#md_include end +-+-\>)")
    foreach ($includeBlock in $includeBlocks) {
        [IncludeOptions]$options = @{
            head           = $includeBlock.Groups["head"].Value
            foot           = $includeBlock.Groups["foot"].Value
            filePath       = $includeBlock.Groups["path"].Value
            asType         = Get-DefaultAsType($includeBlock.Groups["as"].Value)
            from           = Get-DefaultFromNumber($includeBlock.Groups["from"].Value)
            to             = Get-DefaultToNumber($includeBlock.Groups["to"].Value)
            basePath       = $file.DirectoryName
            full           = $includeBlock.Groups["0"].Value
            lang           = $includeBlock.Groups["lang"].Value
            isIncludeBlock = $true
        }
        $new = Invoke-RenderString($options)
        $content = $content.Replace($includeBlock.Groups["0"].Value, $new)
    }
    $content | Out-File $file.FullName -NoNewline
}
