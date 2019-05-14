# Add users
# Version History
# 1.0 - initial script (Roger Kwan)


Param(
    [Parameter(Mandatory=$true)][String] $S,
    [Parameter(Mandatory=$true)][String] $U,
    [Parameter(Mandatory=$false)][String] $P,
	[Parameter(Mandatory=$true)][String] $I
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
$ImportFile=$I #example: '.\userlist2.csv'
$outFile='.\output.txt'

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

function get-userlist {
    param ($user,$pwd,$uri)
    $token=get-token $user $pwd $uri
    $hashtable=@{}
    $header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $request_uri = $uri + '/api/v1/users'
    $header.Add('Authorization','BlueprintToken '+$token)
    $header.Add('Accept','application/json')
    $header.Add('Content-Type','text/json')
    $response = Invoke-RestMethod -Uri $request_uri -Method Get -Headers $header
    # Convert to hashtable
    $output = ConvertTo-JSON -InputObject $response
    foreach($output in $response)  { $hashtable.Add($output.Name, $output.id) }
    return $hashtable
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
    foreach($output in $response)  { $hashtable.Add($output.Name, $output.id) }
    return $hashtable
}

function insert-user {
    param($user,$pwd,$uri,$ID,$FN,$LN,$DN,$T,$D,$EM,$PW,$GR)
    $token=get-token $user $pwd $uri
    $header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $request_uri = $uri + '/api/v1/users'
    $header.Add('Authorization','BlueprintToken '+$token)
    $header.Add('Accept','application/json')
    $header.Add('Content-Type','text/json')
    $content=@(@{
        Type='User'
        Name="$ID"
        DisplayName = "$DN"
        FirstName = "$FN"
        LastName = "$LN"
        Title="$T"
        GroupIds = $GR
        Department="$D"
        Password="$PW"
        Enabled='true'
        Email="$EM"
    })
    $body = ConvertTo-JSON -InputObject $content
    #add-content -Path $outFile -Value $body
    $response = Invoke-RestMethod -Uri $request_uri -Method Post -Headers $header -Body $body
    return $response
}

function get-groupid {
    param($list)
    [System.Collections.ArrayList]$return = @()
    if ($list -match '\,') {
        $lists = $list.split(",") 
    } else {
        $lists += $list
    }
    foreach($item in $lists) { 
        $return += $GroupList[$item] 
    }
    return $return
}


# MAIN PROGRAM
# obtain master group list with group ids. convert into hashtable for easier reference. 
$today=get-date
set-content -Path $outFile -Value "[$today] Starting script"
$GroupList=get-grouplist $Blueprint_username $Blueprint_password $Blueprint_uri
#write-host "Obtained GroupList..."
[System.Collections.ArrayList]$groupidlist=@()

# obtain master user list with user ids. Needed to check for duplicate user entries.
$UserList=get-userlist $Blueprint_username $Blueprint_password $Blueprint_uri

# Read from spreadsheet 
$csv=import-csv "$ImportFile"
foreach($item in $csv) {

#ID = $($item.UserName) 
#FN = $($item.FirstName)
#LN = $($item.LastName) 
#DN = $($item.DisplayName)
#T  = $($item.Title)
#D  = $($item.Department)
#EM = $($item.Email)
#PW = $($item.Password)
#GR = $($item.Group)

# Check to see if a password has been set. If not, use the default password 'Pas$w0rd'
if ($($item.Password)) {$passwd = $($item.Password) } else {$passwd = 'Pas$w0rd'}

# Check to see if user already exists in Storyteller
if ($UserList[$($item.UserName)]) { 
	add-content -Path $outFile -Value "Skipping user $($item.UserName) - user already exists. "	
	} else { 
	add-content -Path $outFile -Value "Adding user $($item.UserName)"
	$groupidlist += get-groupid($($item.Group))
	$output=insert-user $Blueprint_username $Blueprint_password $Blueprint_uri "$($item.UserName)" "$($item.FirstName)" "$($item.LastName)" "$($item.DisplayName)" "$($item.Title)" "$($item.Department)" "$($item.Email)" "$passwd"  $groupidlist
}

#Reset
$groupidlist=@()
}

exit
