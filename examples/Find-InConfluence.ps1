<#
.SYNOPSIS
    Tool Get-SpaceByKeyInConfluence returns content for given space in Confluence.

.DESCRIPTION
    Tool Get-SpaceByKeyInConfluence returns content for given space in Confluence.
#>
function Get-SpaceByKeyInConfluence {
    param (
        [Parameter()]
        $spaceKey="CORS"
    )

    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8

    $baseUrl = $env:CONF_BASE_URL
 
    # Define your PAT and API URL
    $token = ([System.Environment]::GetEnvironmentVariable("CONFL_PAT", "User"))

    $headers = @{
        "Authorization" = "Bearer $($token)"
        "Accept" = "application/json"
    }

    $apiUrl = "$baseUrl/space$(if ($spaceKey) {"/$spaceKey/content"} else {'?start=1&limit=100'} )" 


    # Make the REST API call 
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get -ContentType "application/json; charset=utf-8"

        
        $response | ConvertTo-Json

        
        <#
        @{ 
            "Task code" = $response.key
            "Task status" = $response.fields.status.name
            "Task name" = $response.fields.summary
            "Task description" = $response.fields.description
        } | ConvertTo-Json
        #>
    } catch {
        @{
            "Error" = "Failed to retrieve Confluence information"
            "ErrorMessage" = $_.Exception.Message
            "TaskCode" = $JiraTaskCode
        } | ConvertTo-Json
        
    }
}



<#
.SYNOPSIS
    Tool Get-PageIdByTitleInConfluence returns page ID by title from Confluence.

.DESCRIPTION
    Tool Get-PageIdByTitleInConfluence returns page ID by title from Confluence space.
#>
function Get-PageIdByTitleInConfluence {
    param (
        [Parameter(Mandatory=$true)]
        [string]$title,
        
        [Parameter()]
        [string]$spaceKey,
        
        [Parameter()]
        [int]$limit = 25
    )

    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8

    $baseUrl = $env:CONF_BASE_URL
 
    $token = ([System.Environment]::GetEnvironmentVariable("CONFL_PAT", "User"))

    $headers = @{
        "Authorization" = "Bearer $($token)"
        "Accept" = "application/json"
    }

    # create CQL
    if ($spaceKey) {
        $cql = "type=page AND title='$title' AND space='$spaceKey'"
    } else {
        $cql = "type=page AND text='$title'"
    }

    
    $encodedCql = [System.Web.HttpUtility]::UrlEncode($cql)
    $apiUrl = "$baseUrl/content/search?cql=$encodedCql&limit=$limit"

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get -ContentType "application/json; charset=utf-8"
        
        if ($response.results -and $response.results.Count -gt 0) {
            # If single page is found, return its ID
            if ($response.results.Count -eq 1) {
                @{
                    "PageId" = $response.results[0].id
                    "Title" = $response.results[0].title
                    "Status" = "Found"
                    "Count" = 1
                } | ConvertTo-Json
            }
            # If multiple pages are found, return a list of all matching results.
            else {
                $pages = @()
                foreach ($page in $response.results) {
                    $pages += @{
                        "PageId" = $page.id
                        "Title" = $page.title
                        "Url" = "$($env:CONF_BASE_URL.replace("/rest/api",$page._links.webui))"
                    }
                }
                
                @{
                    "Pages" = $pages
                    "Count" = $response.results.Count
                    "Status" = "Multiple pages found"
                } | ConvertTo-Json -Depth 5
            }
        }
        else {
            @{
                "PageId" = $null
                "Title" = $title
                "Status" = "Not found"
                "SpaceKey" = $spaceKey
            } | ConvertTo-Json
        }
        
    } catch {
        @{
            "Error" = "Failed to search page by title"
            "ErrorMessage" = $_.Exception.Message
            "Title" = $title
            "SpaceKey" = $spaceKey
        } | ConvertTo-Json
    }
}



<#
.SYNOPSIS
    Tool Get-PageByIdInConfluence returns page content by ID from Confluence.

.DESCRIPTION
    Tool Get-PageByIdInConfluence returns page content by ID from Confluence.
#>
function Get-PageByIdInConfluence {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline = $true)]
        [string]$pageId,
        
        [Parameter()]
        [string]$expand = "body.storage,version"
    )

    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8

    $baseUrl = $env:CONF_BASE_URL
 
    $token = ([System.Environment]::GetEnvironmentVariable("CONFL_PAT", "User"))

    $headers = @{
        "Authorization" = "Bearer $($token)"
        "Accept" = "application/json"
    }

    $apiUrl = "$baseUrl/content/$pageId/?expand=$expand"

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get -ContentType "application/json; charset=utf-8"
        
        $response | ConvertTo-Json -Depth 10
        
    } catch {
        @{
            "Error" = "Failed to retrieve page information"
            "ErrorMessage" = $_.Exception.Message
            "PageId" = $pageId
        } | ConvertTo-Json
    }
}


<#
.SYNOPSIS
    Tool Get-ChildPagesInConfluence returns child pages for given page in Confluence.

.DESCRIPTION
    Tool Get-ChildPagesInConfluence returns child pages for given page in Confluence.
#>
function Get-ChildPagesInConfluence {
    param (
        [Parameter(Mandatory=$true)]
        [string]$pageId,
        
        [Parameter()]
        [int]$limit = 25,
        
        [Parameter()]
        [int]$start = 0
    )

    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8

    $baseUrl = $env:CONF_BASE_URL
 
    $token = ([System.Environment]::GetEnvironmentVariable("CONFL_PAT", "User"))

    $headers = @{
        "Authorization" = "Bearer $($token)"
        "Accept" = "application/json"
    }

    $apiUrl = "$baseUrl/content/$pageId/child/page?limit=$limit&start=$start"

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get -ContentType "application/json; charset=utf-8"
        
        $response.results | ForEach-Object {
            $item = $_
            $item._links.webui = ($env:CONF_BASE_URL).replace("/rest/api",$page._links.webui)
            $item
        } | ConvertTo-Json -Depth 10 | Write-Output



    } catch {
        @{
            "Error" = "Failed to retrieve child pages"
            "ErrorMessage" = $_.Exception.Message
            "PageId" = $pageId
        } | ConvertTo-Json
    }
}


<#
.SYNOPSIS
    Tool Search-PageByBodyContentInConfluence searches pages by substring in their body content.

.DESCRIPTION
    Tool Search-PageByBodyContentInConfluence searches pages by substring in their body content within specified space.
#>
function Search-PageByBodyContentInConfluence {
    param (
        [Parameter(Mandatory=$true)]
        [string]$searchText,
        
        [Parameter()]
        [string]$spaceKey,
        
        [Parameter()]
        [int]$limit = 25,
        
        [Parameter()]
        [int]$start = 0
    )

    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8

    $baseUrl = $env:CONF_BASE_URL
 
    $token = ([System.Environment]::GetEnvironmentVariable("CONFL_PAT", "User"))

    $headers = @{
        "Authorization" = "Bearer $($token)"
        "Accept" = "application/json"
    }

    # create CQL
    if ($spaceKey) {
        $cql = "type=page AND text~'$searchText' AND space='$spaceKey'"
    } else {
        $cql = "type=page AND text~'$searchText'"
    }
    
    $encodedCql = [System.Web.HttpUtility]::UrlEncode($cql)
    $apiUrl = "$baseUrl/content/search?cql=$encodedCql&limit=$limit&start=$start&expand=body.storage"

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get -ContentType "application/json; charset=utf-8"
        
        if ($response.results -and $response.results.Count -gt 0) {
            $pages = @()
            foreach ($page in $response.results) {
                # extract body text around the finding
                $bodyText = if ($page.body.storage.value) { 
                    # clear HTML tags
                    $cleanText = $page.body.storage.value -replace '<[^>]+>', ''
                    $cleanText
                } else { "" }
                
                # find match position
                $searchPosition = $bodyText.IndexOf($searchText)
                $excerpt = ""
                if ($searchPosition -ge 0) {
                    $startPos = [Math]::Max(0, $searchPosition - 100)
                    $length = [Math]::Min(200, $bodyText.Length - $startPos)
                    $excerpt = $bodyText.Substring($startPos, $length).Trim()
                }
                
                $pages += @{
                    "PageId" = $page.id
                    "Title" = $page.title
                    "SpaceKey" = $page.space.key
                    "Url" = ($env:CONF_BASE_URL).replace("/rest/api",$page._links.webui)
                    "Excerpt" = $excerpt
                    "HasMatch" = ($searchPosition -ge 0)
                }
            }
            
            @{
                "Pages" = $pages
                "TotalCount" = $response.results.Count
                "SearchText" = $searchText
                "Status" = "Search completed"
            } | ConvertTo-Json -Depth 5
        }
        else {
            @{
                "Pages" = @()
                "TotalCount" = 0
                "SearchText" = $searchText
                "Status" = "No pages found"
            } | ConvertTo-Json
        }
        
    } catch {
        @{
            "Error" = "Failed to search pages by body content"
            "ErrorMessage" = $_.Exception.Message
            "SearchText" = $searchText
            "SpaceKey" = $spaceKey
        } | ConvertTo-Json
    }
}



<#
.SYNOPSIS
    Tool Search-ContentInConfluence searches content in Confluence.

.DESCRIPTION
    Tool Search-ContentInConfluence searches content in Confluence by CQL query.
#>
function Search-ContentInConfluence {
    param (
        [Parameter(Mandatory=$true)]
        [string]$cql,
        
        [Parameter()]
        [int]$limit = 25,
        
        [Parameter()]
        [int]$start = 0
    )

    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8

    $baseUrl = $env:CONF_BASE_URL
 
    $token = ([System.Environment]::GetEnvironmentVariable("CONFL_PAT", "User"))

    $headers = @{
        "Authorization" = "Bearer $($token)"
        "Accept" = "application/json"
    }

    $encodedCql = [System.Web.HttpUtility]::UrlEncode($cql)
    $apiUrl = "$baseUrl/content/search?cql=$encodedCql&limit=$limit&start=$start"

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get -ContentType "application/json; charset=utf-8"
        
        $response.results | ConvertTo-Json -Depth 5
        
    } catch {
        @{
            "Error" = "Failed to search content"
            "ErrorMessage" = $_.Exception.Message
            "CQL" = $cql
        } | ConvertTo-Json
    }
}



<#
.SYNOPSIS
    Tool New-PageInConfluence creates a new page in Confluence.

.DESCRIPTION
    Tool New-PageInConfluence creates a new page in Confluence space.
#>
function New-PageInConfluence {
    param (
        [Parameter(Mandatory=$true)]
        [string]$spaceKey,
        
        [Parameter(Mandatory=$true)]
        [string]$title,
        
        [Parameter(Mandatory=$true)]
        [string]$body,
        
        [Parameter()]
        [string]$parentId
    )

    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8

    $baseUrl = $env:CONF_BASE_URL
 
    $token = ([System.Environment]::GetEnvironmentVariable("CONFL_PAT", "User"))

    $headers = @{
        "Authorization" = "Bearer $($token)"
        "Accept" = "application/json"
        "Content-Type" = "application/json"
    }

    $bodyObject = @{
        type = "page"
        title = $title
        space = @{
            key = $spaceKey
        }
        body = @{
            storage = @{
                value = $body
                representation = "storage"
            }
        }
    }

    if ($parentId) {
        $bodyObject.ancestors = @(@{id = $parentId})
    }

    $apiUrl = "$baseUrl/content"

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Post -Body ($bodyObject | ConvertTo-Json -Depth 10) -ContentType "application/json; charset=utf-8"
        
        @{
            "PageId" = $response.id
            "Title" = $response.title
            "Status" = "Created successfully"
            "Url" = $response._links.webui
        } | ConvertTo-Json
        
    } catch {
        @{
            "Error" = "Failed to create page"
            "ErrorMessage" = $_.Exception.Message
            "Title" = $title
        } | ConvertTo-Json
    }
}



<#
.SYNOPSIS
    Tool Update-PageInConfluence updates an existing page in Confluence.

.DESCRIPTION
    Tool Update-PageInConfluence updates an existing page in Confluence.
#>
function Update-PageInConfluence {
    param (
        [Parameter(Mandatory=$true)]
        [string]$pageId,
        
        [Parameter(Mandatory=$true)]
        [string]$title,
        
        [Parameter(Mandatory=$true)]
        [string]$body,
        
        [Parameter(Mandatory=$true)]
        [int]$version
    )

    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8

    $baseUrl = $env:CONF_BASE_URL
 
    $token = ([System.Environment]::GetEnvironmentVariable("CONFL_PAT", "User"))

    $headers = @{
        "Authorization" = "Bearer $($token)"
        "Accept" = "application/json"
        "Content-Type" = "application/json"
    }

    $bodyObject = @{
        id = $pageId
        title = $title
        body = @{
            storage = @{
                value = $body
                representation = "storage"
            }
        }
        version = @{
            number = $version
        }
    }

    $apiUrl = "$baseUrl/content/$pageId"

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Put -Body ($bodyObject | ConvertTo-Json -Depth 10) -ContentType "application/json; charset=utf-8"
        
        @{
            "PageId" = $response.id
            "Title" = $response.title
            "Status" = "Updated successfully"
            "Version" = $response.version.number
        } | ConvertTo-Json
        
    } catch {
        @{
            "Error" = "Failed to update page"
            "ErrorMessage" = $_.Exception.Message
            "PageId" = $pageId
        } | ConvertTo-Json
    }
}


