# Database connection parameters
$username = "powercard"
$password = "pcard001"
$connectionString = "192.168.0.134:1521/pcard" # TNS entry or host:port/service_name

#Folders
$LogDir = "./log_files"
$afterRunDir = './after_run'




#variables
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# START JS2803C - added a prompt to take the folder name as input
$currentDir = Read-Host -Prompt "Enter the folder name"
#START JS2803E - restored the variable

#END JS2803E
# START JS2803D - Execute only if the path exists
if((Test-Path -Path "./sql_files/$currentDir"))
{
    Write-Host "file path found."
    [System.Console]::Clear()
# END JS2803D
$dirPath = "./sql_files/$currentDir\*"
#Initial setup
#clear log file dir
Remove-Item -Path "$LogDir\*" -Recurse
#START JS2603C - create folders if they do not exist
if (!(Test-Path -Path "$LogDir")) {
    Write-Host "Path not found. Creating $LogDir"
    New-Item -ItemType Directory -Path "$LogDir"
}

if (!(Test-Path -Path "$afterRunDir")) {
    New-Item -ItemType Directory -Path "$afterRunDir"
}

if (!(Test-Path -Path "$Logdir/$currentDir")) {
    Write-Host "Path not found. Creating $Logdir/$currentDir"
    New-Item -ItemType Directory -Path "$Logdir/$currentDir" 
}
#END JS2603C




# Get all directories in a specific location
# JS2803A  START commenting as these are not needed
# $directories = Get-ChildItem -Path "./sql_files" -Directory
# JS2803A  END 

# Loop through each directory
# JS2803B  START removing the foreach loop in recent iteration
# foreach ($dir in $directories) {
# JS2803B  END
    # Write-Host "Processing directory: $($dir.FullName)"

    # $sqlFiles = Get-ChildItem -Path $dir.FullName -Filter "*.sql"
    # START JS2803E - Changing the filter to remove recurse
    # $sqlFiles = Get-ChildItem -Path $dir.FullName -Include "*.sql", "*.pks", "*.pkb" -Recurse | Sort-Object Extension -Descending
    $sqlFiles = Get-ChildItem -Path $dirPath -Include "*.sql", "*.pks", "*.pkb"  | Sort-Object Extension -Descending
    Write-Host $sqlFiles
    foreach ($file in $sqlFiles) {
        #START JS2603 - Changes the log file name to include the folder name
        #$LogFile = "$LogDir/$dir_$($file.Name)_$Timestamp.log"
        $LogFile = "$LogDir/$currentDir/$($file.Name)_$Timestamp.log"
        #END JS2603
    # Header for log file
"===== SQL Execution Log - Started $(Get-Date) =====" | Out-File -FilePath $LogFile
"Directory: $currentDir" | Out-File -FilePath $LogFile -Append
"================================================" | Out-File -FilePath $LogFile -Append

"`n" | Out-File -FilePath $LogFile -Append
Write-Host "Executing: $currentDir/$($file.Name) at $(Get-Date -Format 'HH:mm:ss')"

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

    Write-Host "Execution completed. See $LogFile for details." 
    # Write-Host "current file path - $file"
    # Write-Host "Destination file path - $afterRunDir\$folderName\$($file.Name)"

    
    }
# START JS2803D
}
# END JS2803D
# JS2803B  START removing the foreach loop in recent iteration
# }
else {
    Write-Host "Path not found."
}
# JS2803B  END