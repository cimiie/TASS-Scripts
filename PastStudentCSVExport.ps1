# Created by Trevor Ciminelli.
# TASS token and URL creation created by Sam Fisher(The Alpha School System).
# Created using documentation located at https://github.com/TheAlphaSchoolSystemPTYLTD.
# Date created: 23/02/2020.

# This script will return non-current students of the previous day and export to CSV.
# Script must be run after midnight(12:00AM) and will return students made non-current the day before.
# Example date of leaving = 22/02/2020, running this script at 3:00AM 23/02/2020 will return all students where dol = 22/02/2020.


# Set below variables as required.

# Generated in TASS API Gateway Maintenance program.
$tokenKey    = 'x8FWQUedjyiUGlTf5appPQ=='

# Specified upon API setup in TASS API Gateway Maintenance program.
$appCode     = 'DEMOAPP'

# TASS company to work with (see top right of TASS.web).
$companyCode = '10'

# TASS API version.
$apiVersion  = '2'

# TASS API method.
$method      = "getStudentsDetails"

# TASS API endpoint.
$endpoint    = "https://api.tasscloud.com.au/tassweb/api/"


#Location to export CSV.

$csv = 'c:\temp\paststudents.csv'



## End of user defined variables ## 


# Parameters to pass through in API call.
$parameters  = '{"currentstatus":"noncurrent"}'

# Configure TASS URL parameters.

$URLparameters = @{
Endpoint = $endpoint
Method = $method
AppCode = $appCode
CompanyCode = $companyCode
ApiVersion = $apiVersion
Parameters = $parameters
TokenKey = $tokenKey}


# Convert get-date to datetime.
$convertDate = [Datetime]::ParseExact(((Get-Date).AddDays(-1)).toshortdatestring(), 'dd/MM/yyyy', $null)



# Function to decrypt and encrypted token used in the API call.
function Get-TASSEncryptedToken($TokenKey, $Parameters)
{
    # Convert encryption token from Base64 encoding to byte array.
    $keyArray = [System.Convert]::FromBase64String($TokenKey)

    # Store the string to be encrypted as a byte array.
    $toEncryptArray = [System.Text.Encoding]::UTF8.GetBytes($Parameters)

    # Create a cryptography object with the necessary settings.
    $rDel = New-Object System.Security.Cryptography.RijndaelManaged
    $rDel.Key = $keyArray
    $rDel.Mode = [System.Security.Cryptography.CipherMode]::ECB
    $rDel.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $rDel.BlockSize = 128;

    # Encrypt, return as a byte array, and convert to a Base 64 encoded string. 
    $cTransform = $rDel.CreateEncryptor($keyArray, $null)
    [byte[]]$resultArray = $cTransform.TransformFinalBlock($toEncryptArray, 0, $toEncryptArray.Length)
    $resultBase64 = [System.Convert]::ToBase64String($resultArray, 0, $resultArray.Length)

    # Return as Base 64 encoded string. 
    return $resultBase64
}

# Function to generate a HTTPS GET request URL. 
function Get-TASSUrlRequest ($Endpoint, $Method, $AppCode, $CompanyCode, $ApiVersion, $Parameters, $TokenKey)
{
    # Encrypt the token.
    $encryptedToken = Get-TASSEncryptedToken -tokenKey $TokenKey -parameters $Parameters
    
    # Import the System.Web assembly and use it to URL encode the encrypted token.
    Add-Type -AssemblyName System.Web
    $encryptedTokenUrlEncoded = [System.Web.HttpUtility]::UrlEncode($encryptedToken)
    
    # Build the URL.
    $requestURL = "{0}?method={1}&appcode={2}&company={3}&v={4}&token={5}" -f $Endpoint, $Method, $AppCode, $CompanyCode, $ApiVersion, $encryptedTokenUrlEncoded 
    
    # Return the generated URL.
    return $requestURL
}


# Generate TASS URL.
$url = Get-TASSUrlRequest @URLparameters
# Invoke web request.
$request = Invoke-RestMethod $url
# Return students and export.
$request.students.general_details | Where-Object {[datetime]::parseexact($_.date_of_leaving, 'dd/MM/yyyy', $null) -eq $convertDate} | export-csv $csv