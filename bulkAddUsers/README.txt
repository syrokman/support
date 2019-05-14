addUser Powershell script

DESCRIPTION: 
Bulk import for user information. Users are added if the login name does not exist within the Blueprint instance specified. If a login name exists, the user is skipped. The script can assign group membership to users, provided the groups have already been defined within Blueprint. To assign a user to a group, the Group column in the .csv file needs to be populated.  The text Group names need to be listed in the Group column in the .csv file. If a user requires membership to multiple groups, add the group names separated by a comma in the Group column. If the group name is incorrectly entered into the csv file (such as spelling mistake), the user will not be added to that group. Use the 'getGroupList.ps1' script to obtain a listing of the groups in Blueprint. Any output is sent to the external file '.\output.txt' which will display which users have been added or skipped.


USAGE: 
getGroupList.ps1 -S Blueprint_URL -U login [-P password]
addusers.ps1 -S Blueprint_URL -U login [-P password] -I csv_file


CSV FILE REQUIREMENTS: 
csv file must contain the following information:
 Last Name,First Name,Display Name,Title,Department,Email,User Name,Group,Password



SAMPLE RUN:
PS> .\getGroupList.ps1  -S http://localhost:8080 -U admin
Please input password for account 'admin': ********
System Standards and Compliance Librarian
System Standards and Compliance User
 _Lic

PS> cat .\userlist-template.csv
LastName,FirstName,DisplayName,Title,Department,Email,UserName,Group,Password
Fury,Nick,Nick Fury,Director,SHIELD,nick.fury@shield.gov,nfury," _Lic,System Standards and Compliance Librarian,System S
tandards and Compliance User",Pas$w0rd
Stark,Tony,Tony Stark,Ironman,Avengers,tony.stark@avengers.org,tstark," _Lic,System Standards and Compliance User",Pas$w
0rd
Rogers,Steve,Steve Rogers,Capt.America,Avengers,steve.rogers@avengers.org,srogers," _Lic,System Standards and Compliance
 User",Pas$w0rd
Coulson,Phil,Phil Coulson,Agent,SHIELD,phil.coulson@shield.gov,pcoulson, _Lic,Pas$w0rd
Romanova,Natalia,Natasha Romanova,Black Widow ,Avengers,natasha.romanova@avengers.org,nromanova," _Lic,System Standards a
nd Compliance User",Pas$w0rd
PS>

PS> .\addusers.ps1 -S http://localhost:8080 -U admin -I .\userlist-template.csv
Please input password for account 'admin': ********
PS> cat output.txt
[05/01/2019 13:49:22] Starting script
Skipping user admin - user already exists.
Adding user nfury
Adding user tstark
Adding user srogers
Adding user pcoulson
Adding user nromanova
PS>
