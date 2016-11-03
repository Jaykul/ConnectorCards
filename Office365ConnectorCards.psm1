#requires -Module Configuration

function Set-ConnectorUrl {
    [CmdletBinding()]
    param(
        [string]$Group,
        [string]$Channel,
        [string]$Url
    )

    $Existing = Import-Configuration

    if(!$Existing -or $Existing -isnot [hashtable]) {
        $Existing = @{}
    }
    $Existing["${Group}:${Channel}"] = $Url

    Export-Configuration $Existing
}


function New-Section {
    [CmdletBinding()]
    param(
        
        [Parameter()]
        [string]$SectionName,

        [Parameter()]
        [string]$Summary,

        [Parameter()]
        [string]$Title,
        
        [Parameter()]
        [string]$Subtitle,
        
        [Parameter()]
        [string]$FullText,
        
        [Parameter()]
        [ValidateScript({ if($_ -notmatch "http.?://.*\..*") { throw "ImageUrl must be an http: or https: url" } else { $true }})]
        [string]$AvatarUrl,

        [hashtable]$Facts,

        [hashtable]$Images,

        [hashtable[]]$Actions,

        [switch]$DisableMarkdown
    )

    $Activity = @{
        markdown = (!$DisableMarkdown).ToString().ToLower()
    }

    if($SectionName){ $Activity["title"]            = $SectionName }

    # These ones go together:
    if($AvatarUrl){   $Activity["activityImage"]    = $AvatarUrl   }
    if($Title){       $Activity["activityTitle"]    = $Title       }
    if($Subtitle){    $Activity["activitySubTitle"] = $Subtitle    }
    if($FullText){    $Activity["activityText"]     = $FullText    }

    if($Facts) {
        $Activity["facts"] = @(
            foreach($item in $Facts.GetEnumerator()) {
                @{name = $item.Key; value = $item.Value}
            }
        )
    }
    if($Images) {
        $Activity["images"] = @(
            foreach($item in $Images.GetEnumerator()) {
                @{title = $item.Key; image = $item.Value}
            }
        )
    }

    if($Actions) {
        $Activity["potentialAction"] = @(
            foreach($potential in $Actions) {
                foreach($item in $potential.GetEnumerator()) {
                    @{
                        "@context"= "http://schema.org"
                        "@type"= "ViewAction"
                        name = $item.Key
                        target = @( $item.Value )
                    }
                }
            }
        )
    }

    if($Summary) {
        $Activity["text"] = $Summary
    }

    $Activity
}

function Send-Card {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory)]
        [string]$Group,

        [Parameter(Position=1,Mandatory)]
        [string]$Channel,

        # The message title. Rendered at the top. No markdown
        [string]$Title,

        # An optional simple summary. No markdown
        [string]$Summary,

        # The main message text of the card, supports markdown
        [Parameter(Position=2,Mandatory,ValueFromPipeline)]
        [string]$Message,

        [hashtable[]]$Sections,

        [hashtable[]]$Actions,

        [string]$themeColor = "E81123"

    )

    begin {
        $Configuration = Import-Configuration
        $Key = "${Group}:${Channel}"
        if($Configuration.ContainsKey($Key)) {
            $Uri = $Configuration[$Key]
        } else { 
            throw "Channel '$Channel' not configured for '$Group', please call Set-ConnectorUrl."
        }
    }
    process {

        $Card = @{ text = $Message }

        if($Title){      $Card["title"]      = $Title      }
        if($Summary){    $Card["summary"]    = $Summary    }
        if($themeColor){ $Card["themeColor"] = $themeColor }

        # We're trusting that you created these with New-Section ...
        if($Sections){ $Card["sections"] = $Sections }

        if($Actions) {
            $Card["potentialAction"] = @(
                foreach($potential in $Actions) {
                    foreach($item in $potential.GetEnumerator()) {
                        @{
                            "@context"= "http://schema.org"
                            "@type"= "ViewAction"
                            name = $item.Key
                            target = @( $item.Value )
                        }
                    }
                }
            )
        }

        $Body = ConvertTo-Json $Card -Depth 10
        Write-Verbose $Body
        $Result = Invoke-RestMethod -Uri $Uri -Method Post -ContentType 'application/json' -Body $Body
        if($Result -ne 1) {
            Write-Warning "$Result`n$Body"
        }
    }
}

