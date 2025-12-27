function Get-JiraTaskInfo {
    param (
        [Parameter()]
        $JiraTaskCode="CODE-111222"
    )

    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8

    # Define your PAT and API URL
    $token = [System.Environment]::GetEnvironmentVariable("JIRA_PAT", "User")
    $baseUrl = $env:JIRA_BASE_URL
    # Create the Authorization header with the Bearer token
    $headers = @{
        "Authorization" = "Bearer $token"
        "Accept" = "application/json"
    }
    $apiUrl = "$baseUrl/rest/api/2/issue/$($JiraTaskCode)"

    # Make the REST API call
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get -ContentType "application/json; charset=utf-8"

        @{ 
            "Task code" = $response.key
            "Task status" = $response.fields.status.name
            "Task name" = $response.fields.summary
            "Task description" = $response.fields.description
        } | ConvertTo-Json
    } catch {
        @{
            "Error" = "Failed to retrieve Jira task information"
            "ErrorMessage" = $_.Exception.Message
            "TaskCode" = $JiraTaskCode
        } | ConvertTo-Json
    }
}
