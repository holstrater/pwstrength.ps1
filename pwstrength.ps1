#Create password variables

clear
Write-Host -NoNewLine "Checking if a stable connection to the internet can be made..."

if ((Test-Connection 8.8.8.8 -Quiet) -eq $True) {
    Write-Host " Done.`n" -ForegroundColor green
}
else {
    Write-Host " No stable connection could be made. Please check your internet connection and rerun this script later."
    break
}

Write-Host "Welcome to pwstrength.ps1, a tool that checks the strength of potential passwords."
Write-Host "You will be asked to enter a (potential) password, after which a number of checks will be made to evaluate its strength as a password."
Write-Host "Its strength will then be shown to you, measured as a number out of 100 (the maximum score)."
Write-Host "Whatever you enter next will not be displayed to the screen. This will be censored completely."
Write-Host "When the script exits, it automatically erases your input making sure that no passwords will be saved. `n`n"
Write-Host -NoNewLine "Enter the password that you want to check: "
$pw_secure = Read-Host -AsSecureString
$pw_bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($pw_secure)
$pw_string = [Runtime.InteropServices.Marshal]::PtrToStringAuto($pw_bstr)

$strength = 0

Write-Host "`n"

#Check if password is commonly used by others
Write-Host -NoNewLine "Checking if password is commonly used by others..."

$common = Invoke-WebRequest -UseBasicParsing https://github.com/danielmiessler/SecLists/blob/master/Passwords/darkweb2017-top10000.txt

if (($common.toString() -split "[`r`n]" | Select-String "$pw_string" -SimpleMatch) -ne $Null) {
    Write-Host " Password can be found in a list of most common passwords. Do not use!"
    break
}
else {
    $strength+= 10
}

Write-Host " Done.`n" -ForegroundColor green

#Check if password already (partly) exists in plaintext on local device
$ErrorActionPreference='silentlycontinue'
Write-Host -NoNewLine "Checking if password already (partly) exists in plaintext on local device... This might take a minute or two."

$local = ls c:/ -Recurse -Include *.txt, *.odt, *.docx, *.doc | select-string "$pw_string" -simplematch -verbose:$false
if ($local -ne $null) {
    Write-Host "Password already exists locally. Do not use!"
    break
}
else {
    $strength+= 10
}

Write-Host " Done.`n" -ForegroundColor green
$ErrorActionPreference='continue'

#Check password length
Write-Host -NoNewLine "Checking length..."

$pw_length = ($pw_string | select -expandproperty length)

if ($pw_length -in 10..14) {
    $strength+= 10
}
elseif ($pw_length -in 15..19) {
    $strength+= 20
}
elseif ($pw_length -ge 20) {
    $strength+= 35
}

Write-Host " Done." -ForegroundColor green
Write-Host -NoNewLine "Password strength after checking for character length: "; Write-Host -ForegroundColor Yellow "$strength/100`n"

#Check special characters
Write-Host -NoNewLine "Checking special characters..."

$special_length = 0
$special = " !`"#$%&'()*+,-./:;<=>?@[\]^_``{|}~".toCharArray()
$pw_array = $pw_string.toCharArray()
$min = 0.1
$max = 0.9

$pw_array | ForEach-Object { `
    if ($special -like $_) {
        $special_length+= 1
    }
}

if ($($special_length/$pw_length) -ge $min -and $($special_length/$pw_length) -le $max) {
    $strength+= 15
}

Write-Host " Done." -ForegroundColor green
Write-Host -NoNewLine "Password strength after checking for special characters: "; Write-Host -ForegroundColor Yellow "$strength/100`n"

#Check for upper- and lowercase combination
Write-Host -NoNewLine "Checking uppercase characters..."

$capital_length = 0
$capitals = [char[]](65..90)

$pw_array | ForEach-Object { `
    if ($capitals -clike $_) {
        $capital_length+= 1
    }
}

if ($($capital_length/$pw_length) -ge $min -and $($capital_length/$pw_length) -le $max) {
    $strength+= 15
}

Write-Host " Done." -ForegroundColor green
Write-Host -NoNewLine "Password strength after checking for uppercase characters: "; Write-Host -ForegroundColor Yellow "$strength/100`n"

#Check for numbers
Write-Host -NoNewLine "Checking number characters..."

$numbers_length = 0
$numbers = (0..9)

$pw_array | ForEach-Object { `
    if ($numbers -like $_) {
        $numbers_length+= 1
    }
}

if ($($numbers_length/$pw_length) -ge $min -and $($numbers_length/$pw_length) -le $max) {
    $strength+= 15
}

Write-Host " Done." -ForegroundColor green
Write-Host -NoNewLine "Password strength after checking for numbers: "; Write-Host -ForegroundColor Yellow "$strength/100`n"

#Removing password variables from local scope just in case

rv pw_secure, pw_bstr, pw_string, pw_array, pw_length, local, special_length, capital_length, numbers_length
