#getGroupList.ps1
# Version History
# 1.0 - initial script (Roger Kwan)

Param(
    [Parameter(Mandatory=$true)][String] $S,
    [Parameter(Mandatory=$true)][String] $U,
    [Parameter(Mandatory=$false)][String] $P
)

if($P){ 
$securePassword = $P
} else {
    $securePassword = Read-Host "Please input password for account '$U'" -AsSecureString
}
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword) 
$pwd  = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)


$Blueprint_username=$U #example: 'admin'
$Blueprint_password=$pwd #example: 'changeme'
$Blueprint_uri=$S #example: 'http://localhost:8080'

function get-token{
    # needed parameters 
    param($user,$pwd,$uri)
    $header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $request_uri = $uri + '/authentication/v1/login'
    # concatenate the username and password with : as required by rfc2617
    $creds = $user+":"+$pwd
    # encode in utf-8 and perform base64 encoding
    $auth_byte = [System.Text.Encoding]::UTF8.GetBytes($creds)
    $auth_encode =[System.Convert]::ToBase64String($auth_byte)
    # make request using GET
    $header.Add('Authorization','Basic '+$auth_encode)
    $header.Add('Accept','application/json')
    $response = Invoke-RestMethod -Uri $request_uri -Method Get -Headers $header
    return $response
}

function get-grouplist {
    param ($user,$pwd,$uri)
    $token=get-token $user $pwd $uri
    $hashtable=@{}
    $header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $request_uri = $uri + '/api/v1/groups'
    $header.Add('Authorization','BlueprintToken '+$token)
    $header.Add('Accept','application/json')
    $header.Add('Content-Type','text/json')
    $response = Invoke-RestMethod -Uri $request_uri -Method Get -Headers $header
    # Convert to hashtable
    $output = ConvertTo-JSON -InputObject $response
    foreach($output in $response)  { 
	$hashtable.Add($output.Name, $output.id) 
	#write-host $output.Name
	}
    return $hashtable
}

#write-host "Group List"
$GroupList=get-grouplist $Blueprint_username $Blueprint_password $Blueprint_uri

ForEach ($key in $GroupList.keys) {
write-host $key
}