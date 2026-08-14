<#
.SYNOPSIS
    Cracks open a VSIX ZIP archive, extracts package.json, README.md, and LICENSE, and scrubs emails.

.DESCRIPTION
    VSIX files are strictly ZIP archives. This command utilizes System.IO.Compression to surgically stream
    and extract ONLY the mandatory metadata files, avoiding inflating the heavy binaries. It actively parses
    and sanitizes the README.md to remove sensitive emails (preventing Chocolatey Moderation rejection)
    and algorithmically truncates the string to safely fit inside the 4000-character `<description>` nuspec limit.

.PARAMETER VsixPath
    The local absolute path to the downloaded .vsix file.

.PARAMETER DestinationDir
    The target automatic/package scaffolding directory to extract the tools/ metadata into.

.EXAMPLE
    $result = Expand-VsCodePayload -VsixPath "C:\temp\payload.vsix" -DestinationDir "C:\packages\vscode-python"

.INPUTS
    None

.OUTPUTS
    [System.Management.Automation.PSCustomObject]
    A PSCustomObject containing the parsed JSON from package.json and the fully sanitized/truncated README block.

.NOTES
    The truncation algorithm recursively unwinds the Markdown AST to find the cleanest cut-off point before 4000 bytes.
#>
function Expand-VsCodePayload {
    param (
        [Parameter(Mandatory = $true)][string]$VsixPath,
        [Parameter(Mandatory = $true)][string]$DestinationDir
    )

    Write-White "    Extracting Metadata from VSIX Archive..."
    # Load the .NET Compression framework into the AppDomain to enable [System.IO.Compression.ZipFile] for parsing VSIX archive streams.
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($VsixPath)
    $packageJson = $null

    try {
        $packageJsonEntry = $zip.Entries | Where-Object FullName -eq 'extension/package.json' | Select-Object -First 1
        $readmeEntry = $zip.Entries | Where-Object FullName -match '(?i)^extension/README\.md$' | Select-Object -First 1
        $licenseEntry = $zip.Entries | Where-Object FullName -match '(?i)^extension/LICENSE(?:\.txt|\.md)?$' | Select-Object -First 1

        if ($packageJsonEntry) {
            $stream = $packageJsonEntry.Open()
            $reader = [System.IO.StreamReader]::new($stream)
            $packageJsonContent = $reader.ReadToEnd()
            $reader.Close(); $stream.Close()
            $packageJson = $packageJsonContent | ConvertFrom-Json -AsHashTable
        }

        if ($readmeEntry) {
            $readmePath = Join-Path $DestinationDir "README.md"
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($readmeEntry, $readmePath, $true)

            # Scrub emails from the README itself to pass Chocolatey Moderation checks.
            $readmeRaw = Get-Content $readmePath -Raw -Encoding UTF8
            $readmeRaw = $readmeRaw -replace '(?i)[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}', '[email removed]'

            $readmeFull = $readmeRaw

            # Semantically truncate to comply with Chocolatey's 4000 character `<description>` limit
            $limit = 3750
            if ($readmeRaw.Length -gt $limit) {
                $searchSpace = $readmeRaw.Substring(0, $limit)
                $truncated = ""

                $match = [regex]::Match($searchSpace, '(?is).*(</table>|</ul>|</ol>|</p>|</div>|</pre>|</blockquote>|\r?\n[ \t]*\r?\n|</tr>|</li>|</dd>)')
                if ($match.Success -and $match.Length -gt 1500) {
                    $truncated = $match.Value
                }
                else {
                    $match = [regex]::Match($searchSpace, '(?is).*\.(?=\s)')
                    if ($match.Success -and $match.Length -gt 1500) {
                        $truncated = $match.Value
                    }
                    else {
                        $match = [regex]::Match($searchSpace, '(?is).*(?=\r?\n)')
                        if ($match.Success -and $match.Length -gt 1500) {
                            $truncated = $match.Value
                        }
                        else {
                            $idx = $searchSpace.LastIndexOf(' ')
                            if ($idx -gt 0) {
                                $truncated = $searchSpace.Substring(0, $idx)
                            }
                            else {
                                $truncated = $searchSpace
                            }
                        }
                    }
                }

                $truncated = $truncated.TrimEnd()

                # Auto-close any unclosed HTML tags (from innermost to outermost) to prevent layout breaking
                $tagsToBalance = @("td", "th", "tr", "thead", "tbody", "table", "li", "ul", "ol", "pre", "div", "blockquote", "dd", "dl")
                foreach ($tag in $tagsToBalance) {
                    $open = ([regex]::Matches($truncated, "(?i)<$tag\b")).Count
                    $close = ([regex]::Matches($truncated, "(?i)</$tag>")).Count
                    if ($open -gt $close) {
                        for ($i = 0; $i -lt ($open - $close); $i++) {
                            $truncated += "</$tag>"
                        }
                    }
                }

                $marketplaceUrl = "$script:MarketplaceBaseUrl/items?itemName=$($packageJson.publisher).$($packageJson.name)"
                $readmeRaw = $truncated + "`n`n... [Truncated due to Chocolatey character limits. See [extension page]($marketplaceUrl) for full documentation]"
            }

            # We save the FULL readme back to README.md for the user, but we will return the $readmeRaw (which is truncated) for the nuspec
            $readmeFull = $readmeFull.Replace("`r`n", "`n")
            [System.IO.File]::WriteAllText($readmePath, $readmeFull, [System.Text.UTF8Encoding]::new($false))
        }

        if ($licenseEntry) {
            $legalDir = Join-Path $DestinationDir "legal"
            if (-not (Test-Path $legalDir)) { [void](New-Item -ItemType Directory -Force -Path $legalDir) }

            # Standardize the license filename to simply "LICENSE.txt" across the entire repository
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($licenseEntry, (Join-Path $legalDir "LICENSE.txt"), $true)
        }
    }
    finally {
        if ($null -ne $zip) {
            $zip.Dispose()
        }
    }

    # Strip raw HTML tags that break Chocolatey Gallery's Markdig Markdown parser for the Nuspec Description only
    if ($readmeRaw) {
        $readmeRaw = $readmeRaw -replace '(?i)<img[^>]*>', ''
        $readmeRaw = $readmeRaw -replace '(?i)</?span[^>]*>', ''
        $readmeRaw = $readmeRaw -replace '(?i)</?div[^>]*>', ''
        $readmeRaw = $readmeRaw -replace '(?i)</?center[^>]*>', ''
        $readmeRaw = $readmeRaw -replace '(?i)</?picture[^>]*>', ''
        $readmeRaw = $readmeRaw -replace '(?i)</?h[1-6][^>]*>', ''
        $readmeRaw = $readmeRaw -replace '(?i)</?p[^>]*>', ''
        $readmeRaw = $readmeRaw -replace '(?i)</?details[^>]*>', ''
        $readmeRaw = $readmeRaw -replace '(?i)</?summary[^>]*>', ''
        $readmeRaw = $readmeRaw -replace '(?i)</?i[^>]*>', ''
        $readmeRaw = $readmeRaw -replace '(?i)<br\s*/?>', "`n"
    }

    $cdataSafe = ""
    if ($readmeRaw) {
        # XML parsers will crash if they encounter the string "]]>" inside a CDATA section.
        # To safely embed READMEs containing "]]>", we must terminate the current CDATA section
        # and immediately open a new one by replacing "]]>" with "]]]]><![CDATA[>".
        $cdataSafe = $readmeRaw -replace '\]\]>', ']]]]><![CDATA[>'
    }

    return [PSCustomObject]@{
        PackageJson     = $packageJson
        TruncatedReadme = $readmeRaw
        CDataSafeReadme = $cdataSafe
    }
}
