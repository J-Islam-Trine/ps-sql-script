# Database connection parameters
$username = "powercard"
$password = "pcard001"
$connectionString = "192.168.0.134:1521/pcard" # TNS entry or host:port/service_name

#Folders
$LogDir = "./log_files"
$afterRunDir = './after_run'

#START JS2603B - added a variable to control what folder to run on
$currentDir = "000_Sequences"
#END JS2603B

#variables
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

#Initial setup
#clear log file dir
Remove-Item -Path "$LogDir\*"
#START JS2603C - create folders if they do not exist
if (!(Test-Path -Path "$LogDir")) {
    Write-Host "Path not found. Creating $LogDir"
    New-Item -ItemType Directory -Path "$LogDir"
}
if (!(Test-Path -Path "$Logdir/$currentDir")) {
    Write-Host "Path not found. Creating $Logdir/$currentDir"
    New-Item -ItemType Directory -Path "$Logdir/$currentDir" 
}
#END JS2603C

if (!(Test-Path -Path "$afterRunDir")) {
    New-Item -ItemType Directory -Path "$afterRunDir"
}


# Get all directories in a specific location
$directories = Get-ChildItem -Path "./sql_files" -Directory

# Loop through each directory
foreach ($dir in $directories) {
    # Write-Host "Processing directory: $($dir.FullName)"
    
    # $sqlFiles = Get-ChildItem -Path $dir.FullName -Filter "*.sql"
    $sqlFiles = Get-ChildItem -Path $dir.FullName -Include "*.sql", "*.pks", "*.pkb" -Recurse | Sort-Object Extension -Descending
    Write-Host $sqlFiles
    foreach ($file in $sqlFiles) {
        #START JS2603 - Changes the log file name to include the folder name
        #$LogFile = "$LogDir/$dir_$($file.Name)_$Timestamp.log"
        $LogFile = "$LogDir/$dir/$($file.Name)_$Timestamp.log"
        #END JS2603
    # Header for log file
"===== SQL Execution Log - Started $(Get-Date) =====" | Out-File -FilePath $LogFile
"Directory: $dir" | Out-File -FilePath $LogFile -Append
"================================================" | Out-File -FilePath $LogFile -Append

"`n" | Out-File -FilePath $LogFile -Append
Write-Host "Executing: $dir/$($file.Name) at $(Get-Date -Format 'HH:mm:ss')"

# $TempSql = [System.IO.Path]::GetTempFileName() + ".sql"
$tempFile = New-TemporaryFile
#START JS2603A - changed the command to remove trailing space
#"SET PACKAGE OFF`nSET ECHO ON`nSET SERVEROUTPUT ON SIZE 1000000`nSPOOL ./spool.txt append`nWHENEVER SQLERROR EXIT SQL.SQLCODE`n@""$($file.FullName)""`n/`nSPOOL OFF`nEXIT;" | Out-File -FilePath $tempFile -Encoding ASCII
"SET PACKAGE OFF`nSET ECHO ON`nSET SERVEROUTPUT ON SIZE 1000000`nSPOOL ./spool.txt append`nWHENEVER SQLERROR EXIT SQL.SQLCODE`n@""$($file.FullName)""`nSPOOL OFF`nEXIT;" | Out-File -FilePath $tempFile -Encoding ASCII
#END JS2603A
# Run the SQL file and capture output
    $output = sqlplus -L  "$username/$password@$connectionString" "@$tempFile"
   # $output = sqlplus -S "$username/$password@$connectionString" "@$TempSql;"
   # $output = sqlplus "$username/$password@$connectionString"
   $output | ForEach-Object { 
    Write-Host $_
   }

       Write-Output $output | Out-File -FilePath $LogFile -Append
   
    
   # Remove-Item $TempSql
    $ExitCode = $LASTEXITCODE
    if ($ExitCode -eq 0) {
       Write-Host "Status: SUCCESS (Exit code: $ExitCode)"
       "Status: SUCCESS (Exit code: $ExitCode)" | Out-File -FilePath $LogFile -Append
       #move file to someplace else
       $folderName = Split-Path -Path (Split-Path -Path $file -Parent) -Leaf
       
       #Moving successful files to other place
       if (!(Test-Path -Path "$afterRunDir\$folderName\")) {
           New-Item -ItemType Directory -Path "$afterRunDir\$folderName\"
       }

       Move-Item -Path "$file" -Destination "$afterRunDir\$folderName\"
    } else {
       Write-Host "Status: ERROR (Exit code: $ExitCode)"
       "Status: ERROR (Exit code: $ExitCode)" | Out-File -FilePath $LogFile -Append
    }
        "Completed at $(Get-Date -Format 'HH:mm:ss')" | Out-File -FilePath $LogFile -Append
        "----------------" | Out-File -FilePath $LogFile -Append

    Write-Host "Execution completed. See $LogFile for details." .\.git
    # Write-Host "current file path - $file"
    # Write-Host "Destination file path - $afterRunDir\$folderName\$($file.Name)"

    
    }
}