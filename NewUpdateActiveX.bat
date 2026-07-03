@>>C:\CNTRLPTS\Util\NewUpdateActiveX_called.marker echo [%DATE% %TIME%] ENTERED NewUpdateActiveX.bat user=%USERNAME% computer=%COMPUTERNAME% cmd=%CMDCMDLINE%
@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem NewUpdateActiveX.bat keeps the same update workflow as UpdateActiveX.bat,
rem but writes a detailed per-run trace so random logon-script termination can
rem be narrowed to the exact command that did not return.

set "BaseDir=C:\CNTRLPTS\Util"
set "LogDir=%BaseDir%\log"
set "SftpDir=%BaseDir%\sftp"
if not exist "%LogDir%\" mkdir "%LogDir%" 2>nul

for /f "tokens=1-7" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Date -Format 'yyyy MM dd HH mm ss yyyyMMddHHmmss'" 2^>nul') do (
	set "yyyy=%%A"
	set "mm=%%B"
	set "dd=%%C"
	set "hh=%%D"
	set "mi=%%E"
	set "ss=%%F"
	set "RunStamp=%%G"
)
if not defined RunStamp (
	set "yyyy=%DATE:~6,4%"
	set "mm=%DATE:~3,2%"
	set "dd=%DATE:~0,2%"
	set "hh=%TIME:~0,2%"
	set "mi=%TIME:~3,2%"
	set "ss=%TIME:~6,2%"
	set "hh=!hh: =0!"
	set "RunStamp=!yyyy!!mm!!dd!!hh!!mi!!ss!"
)

set "RunId=%COMPUTERNAME%_%RunStamp%_%RANDOM%"
set "TraceLog=%LogDir%\NewUpdateActiveX_%RunId%.trace.log"
set "ScratchFile=%LogDir%\NewUpdateActiveX_%RunId%.tmp"
set "LogFile=%LogDir%\activeXDaily_%yyyy%%mm%%dd%.log"

call :Trace "=================================================="
call :Trace "Script starting"
call :Trace "User=%USERNAME% Computer=%COMPUTERNAME% Session=%SESSIONNAME%"
call :Trace "ScriptPath=%~f0 ScriptDir=%~dp0 CurrentDir=%CD%"
call :Trace "CmdLine=%CMDCMDLINE%"
call :Trace "RunId=%RunId%"

call :Trace "Before cd to script folder"
cd /d "%~dp0"
set "rc=%ERRORLEVEL%"
call :Trace "After cd to script folder rc=%rc% CurrentDir=%CD%"
if not "%rc%"=="0" call :Trace "WARNING: failed to change to script folder; continuing like original script would attempt to continue."

rem ############ Start Clean Temp Files ################
call :Trace "Before temp cleanup in .\sftp\temp"
del .\sftp\temp\* /S /Q >>"%TraceLog%" 2>&1
set "rc=%ERRORLEVEL%"
call :Trace "After temp file cleanup rc=%rc%"
for /d %%i in (.\sftp\temp\*) do (
	call :Trace "Removing temp directory %%i"
	rmdir /s /q "%%i" >>"%TraceLog%" 2>&1
	set "rc=!ERRORLEVEL!"
	call :Trace "Removed temp directory %%i rc=!rc!"
)
rem ############ Finish Clean Temp Files ################

rem ############ Start Workstation Logging ################
call :Trace "Date/time resolved yyyy=%yyyy% mm=%mm% dd=%dd% hh=%hh% mi=%mi% ss=%ss%"
set /a mx=1%mm%-100
set /a dx=1%dd%-100
call :Trace "EPS date parts mx=%mx% dx=%dx%"

call :Trace "Daily log resolved LogFile=%LogFile%"
>>"%LogFile%" echo.
>>"%LogFile%" echo NewUpdateActiveX trace log: %TraceLog%

>>"%LogFile%" echo Get current version
call :Trace "Before reading C:\CNTRLPTS\Version.txt"
set "ver="
if exist "C:\CNTRLPTS\Version.txt" (
	set /p ver=<"C:\CNTRLPTS\Version.txt"
	set "rc=%ERRORLEVEL%"
) else (
	set "rc=missing"
)
call :Trace "After reading Version.txt rc=%rc% ver=%ver%"

>>"%LogFile%" echo Get Control Point
call :ReadFirstMatch "C:\CNTRLPTS\dc.ini" "CNTRL_PT_CD" "cntpnt"

>>"%LogFile%" echo Get Host
call :Trace "Before hostname"
hostname >"%ScratchFile%" 2>>"%TraceLog%"
set "rc=%ERRORLEVEL%"
set "pc_name="
set /p pc_name=<"%ScratchFile%" 2>nul
call :Trace "After hostname rc=%rc% pc_name=%pc_name%"

>>"%LogFile%" echo Get ip
call :Trace "Before ipconfig IPv4 lookup"
ipconfig | findstr /C:IPv4 >"%ScratchFile%" 2>>"%TraceLog%"
set "rc=%ERRORLEVEL%"
call :Trace "After ipconfig IPv4 lookup rc=%rc%"
set "ip="
for /f "tokens=1,2 delims=:" %%A in ('type "%ScratchFile%" 2^>nul') do if not defined ip set "ip=%%B"
for /l %%a in (1,1,150) do if "!ip:~0,1!"==" " set "ip=!ip:~1!"
call :Trace "After IP parse ip=%ip%"

>>"%LogFile%" echo Get Operation Type
call :ReadFirstMatch "C:\CNTRLPTS\dc.ini" "ACCESS_DCO" "isDCO"

>>"%LogFile%" echo Get Webcam Availability
call :ReadFirstMatch "C:\CNTRLPTS\dc.ini" "CAM_ENABLED" "hasCam"

>>"%LogFile%" echo Read Config
call :ReadFirstMatch "C:\CNTRLPTS\Util\psftpSetting.txt" "REMOTE_SERVER_IP" "x"

set dt=%yyyy%_%mm%_%dd%__%hh%_%mi%_%ss%
set dt=%dt: =0%
>>"%LogFile%" echo current date: %dt%
set fromdt=2023_10_30__16_03_00
>>"%LogFile%" echo Using new server ip from %fromdt%
call :Trace "Before server ip adjustment dt=%dt% fromdt=%fromdt% x=%x%"
if %dt% gtr %fromdt% (
	set x=%x:uatint=uat.int%
)
call :Trace "After server ip adjustment x=%x%"
echo using server ip: %x%

set "ftphost=%x:~17%"
call :Trace "ftphost=%ftphost%"
call :ReadFirstMatch "C:\CNTRLPTS\Util\psftpSetting.txt" "REMOTE_USER" "x"
if %dt% gtr %fromdt% (
	set x=%x:2=1%
)
set "ftpuser=%x:~12%"
for /l %%a in (1,1,150) do if "!ftpuser:~-1!"==" " set "ftpuser=!ftpuser:~0,-1!"
call :Trace "ftpuser=%ftpuser%"
call :ReadFirstMatch "C:\CNTRLPTS\Util\psftpSetting.txt" "REMOTE_KEY" "x"
if %dt% gtr %fromdt% (
	set x=%x:2=1%
)
set "ftpkey=%x:~11%"
call :Trace "ftpkey=%ftpkey%"

set "sFtpPath=%SftpDir%\psftp"
set "tempFtpScript=%SftpDir%\%RunId%.ftp"
set "ActnFilePath=%SftpDir%\%pc_name%_%yyyy%%mm%%dd%_%RunId%.updateActiveXLog"
set "AwsFilePath=%SftpDir%\alwaysYes.txt"
set "sFtpKeyPath=%SftpDir%\%ftpkey%"
set "ActnUploadDir=/Log/"
call :Trace "SFTP variables resolved sFtpPath=%sFtpPath% tempFtpScript=%tempFtpScript% ActnFilePath=%ActnFilePath% AwsFilePath=%AwsFilePath% sFtpKeyPath=%sFtpKeyPath%"
call :Trace "Existence check psftp=%sFtpPath% key=%sFtpKeyPath% alwaysYes=%AwsFilePath% sftpDir=%SftpDir%\"

>>"%LogFile%" echo Call ftp for update log
call :Trace "Before creating workstation upload log"
>"%ActnFilePath%" echo -----------------------------------
set "rc=%ERRORLEVEL%"
call :Trace "After first write to ActnFilePath rc=%rc%"
>>"%ActnFilePath%" echo %yyyy%-%mm%-%dd% %hh%:%mi%
>>"%ActnFilePath%" echo %pc_name%
>>"%ActnFilePath%" echo %ip%
>>"%ActnFilePath%" echo %cntpnt%
>>"%ActnFilePath%" echo %ver%
>>"%ActnFilePath%" echo %isDCO%
>>"%ActnFilePath%" echo %hasCam%
>>"%ActnFilePath%" dir /ad /d C:\CNTRLPTS\ 2>&1
>>"%ActnFilePath%" dir /ad /d C:\CCS\ 2>&1
>>"%ActnFilePath%" echo -----------------------------------
call :Trace "After writing workstation upload log"

>"%tempFtpScript%" echo cd %ActnUploadDir%
>>"%tempFtpScript%" echo put %ActnFilePath%
>>"%tempFtpScript%" echo bye
call :Trace "Before SFTP upload of workstation log"
>>"%LogFile%" "%sFtpPath%" -i "%sFtpKeyPath%" -b "%tempFtpScript%" %ftpuser%@%ftphost% < "%AwsFilePath%"
set "rc=%ERRORLEVEL%"
call :Trace "After SFTP upload of workstation log rc=%rc%"

del /q "%ActnFilePath%" >>"%TraceLog%" 2>&1
set "rc=%ERRORLEVEL%"
call :Trace "Deleted ActnFilePath rc=%rc%"
del /q "%tempFtpScript%" >>"%TraceLog%" 2>&1
set "rc=%ERRORLEVEL%"
call :Trace "Deleted tempFtpScript rc=%rc%"
rem ############ Finish Workstation Logging ################

rem ############ Get Daily ActiveX Log ################
set "logFilePath=%SftpDir%\%pc_name%_%yyyy%%mm%%dd%%hh%.ActiveXLog"
set "logEPSPath=%SftpDir%\%pc_name%_%yyyy%%mm%%dd%.EPSLog"
set "logSrcPath=C:\CNTRLPTS\Log\DCSPeripheryCOM_%yyyy%%mm%%dd%.log"
set "epsSrcPath=C:\CNTRLPTS\Log\%yyyy%-%mx%-%dx%.log"
set "logBridgeServiceSrcFile="
for /f "delims=" %%a in ('dir /b /o-d "C:\CNTRLPTS\Log\BridgeService*.log" 2^>nul') do (
	if not defined logBridgeServiceSrcFile set "logBridgeServiceSrcFile=%%a"
)
>>"%LogFile%" echo file %logBridgeServiceSrcFile%
set "logBridgeServiceSrcPath=C:\CNTRLPTS\Log\%logBridgeServiceSrcFile%"
set "logBridgeServicPath=%SftpDir%\%pc_name%_%logBridgeServiceSrcFile%"
call :Trace "Daily log paths logSrcPath=%logSrcPath% epsSrcPath=%epsSrcPath% bridge=%logBridgeServiceSrcPath%"

>>"%LogFile%" echo Stop BridgeService (Restart)
call :Trace "Before net stop BridgeServiceForDCS"
>>"%LogFile%" net stop "BridgeServiceForDCS"
set "rc=%ERRORLEVEL%"
call :Trace "After net stop BridgeServiceForDCS rc=%rc%"

if not "%isDCO%" equ "" (
	if exist "%logSrcPath%" (
		>>"%LogFile%" echo Send ActiveX Com Log
		call :UploadFile "%logSrcPath%" "%logFilePath%" "ActiveX Com Log"
	) else (
		call :Trace "ActiveX Com Log source missing: %logSrcPath%"
	)

	if exist "%epsSrcPath%" (
		>>"%LogFile%" echo Send EPS Log
		call :UploadFile "%epsSrcPath%" "%logEPSPath%" "EPS Log"
	) else (
		call :Trace "EPS Log source missing: %epsSrcPath%"
	)

	if "%logBridgeServiceSrcFile%" neq "" (
		>>"%LogFile%" echo Send Bridge Service Log
		call :UploadFile "%logBridgeServiceSrcPath%" "%logBridgeServicPath%" "Bridge Service Log"
	) else (
		call :Trace "Bridge Service Log source missing"
	)
)
rem ############ Finish Daily ActiveX Log ################

rem ############ Core Update ActiveX ################
set "tempVerNumFile=%BaseDir%\Version.txt"
set "GetVerNumScript=%SftpDir%\%RunId%_getVersionNum.ftp"
set "GetDllScript=%SftpDir%\%RunId%_getLatestDll.ftp"
set "GetOctScript=%SftpDir%\%RunId%_getLatestOct.ftp"
set "tempBakPath=%SftpDir%\temp\%RunId%\bak\"
set "tempDllPath=%SftpDir%\temp\%RunId%\dll\"
set "tempOctPath=%SftpDir%\temp\%RunId%\oct\"
call :Trace "Core paths tempVerNumFile=%tempVerNumFile% tempDllPath=%tempDllPath% tempBakPath=%tempBakPath% tempOctPath=%tempOctPath%"

if exist "%tempVerNumFile%" (
	call :Trace "Deleting old temp version file %tempVerNumFile%"
	del /q "%tempVerNumFile%" >>"%TraceLog%" 2>&1
	set "rc=%ERRORLEVEL%"
	call :Trace "Deleted old temp version file rc=%rc%"
)

if not exist "%tempDllPath%" mkdir "%tempDllPath%" 2>>"%TraceLog%"
set "rc=%ERRORLEVEL%"
call :Trace "Ensure tempDllPath rc=%rc%"
if not exist "%tempOctPath%" mkdir "%tempOctPath%" 2>>"%TraceLog%"
set "rc=%ERRORLEVEL%"
call :Trace "Ensure tempOctPath rc=%rc%"
if not exist "%tempBakPath%" mkdir "%tempBakPath%" 2>>"%TraceLog%"
set "rc=%ERRORLEVEL%"
call :Trace "Ensure tempBakPath rc=%rc%"

rem ############ Start Get Server Version ################
>>"%LogFile%" echo Call ftp for version num
>"%GetVerNumScript%" echo cd CNTRLPTS
>>"%GetVerNumScript%" echo lcd %BaseDir%\
>>"%GetVerNumScript%" echo mget Version.txt
>>"%GetVerNumScript%" echo bye
call :Trace "Before SFTP get version"
>>"%LogFile%" "%sFtpPath%" -i "%sFtpKeyPath%" -b "%GetVerNumScript%" %ftpuser%@%ftphost% < "%AwsFilePath%"
set "rc=%ERRORLEVEL%"
call :Trace "After SFTP get version rc=%rc%"
del /q "%GetVerNumScript%" >>"%TraceLog%" 2>&1
set "rc=%ERRORLEVEL%"
call :Trace "Deleted GetVerNumScript rc=%rc%"
set "nVer="
if exist "%tempVerNumFile%" (
	set /p nVer=<"%tempVerNumFile%"
	set "rc=%ERRORLEVEL%"
) else (
	set "rc=missing"
)
call :Trace "Read latest version rc=%rc% nVer=%nVer%"
rem ############ Finish Get Server Version ################

rem ############ Start Compare Server Version ################
if exist "%tempVerNumFile%" (
	>>"%LogFile%" echo Current version : %ver%
	>>"%LogFile%" echo Latest version : %nVer%
	if "%nVer%" == "%ver%" (
		>>"%LogFile%" echo Current version is latest, no need update
		call :Trace "Current version is latest; going to END"
		goto END
	) else (
		>>"%LogFile%" echo Current version is NOT latest, start update
		call :Trace "Current version differs; continuing update"
	)
) else (
	>>"%LogFile%" echo Get latest version failed
	call :Trace "Get latest version failed; going to END"
	goto END
)
rem ############ Done Compare Server Version ################

rem ############ Start Get latest ActiveX file ################
>>"%LogFile%" echo Call ftp for latest activeX file
>"%GetDllScript%" echo cd CNTRLPTS
>>"%GetDllScript%" echo lcd %tempDllPath%
>>"%GetDllScript%" echo mget -r *
>>"%GetDllScript%" echo bye
call :Trace "Before SFTP get latest ActiveX file"
>>"%LogFile%" "%sFtpPath%" -i "%sFtpKeyPath%" -b "%GetDllScript%" %ftpuser%@%ftphost% < "%AwsFilePath%"
set "rc=%ERRORLEVEL%"
call :Trace "After SFTP get latest ActiveX file rc=%rc%"
rem ############ Finish Get latest ActiveX file ################

rem ############ Check ActiveX file ################
>>"%LogFile%" echo backup current file
call :Trace "Before backup loop from %tempDllPath%"
for /f "delims=" %%f in ('dir "%tempDllPath%" /b /a-d-h-s 2^>nul') do (
	set "fname=C:\CNTRLPTS\%%f"
	if exist "!fname!" (
		copy "!fname!" "%tempBakPath%" >>"%TraceLog%" 2>&1
		set "rc=!ERRORLEVEL!"
		call :Trace "Backed up !fname! rc=!rc!"
	) else (
		call :Trace "Backup source missing !fname!"
	)
)

rem ############ Update current ActiveX file to latest ################
>>"%LogFile%" echo Copy files
call :Trace "Before xcopy ActiveX files"
>>"%LogFile%" xcopy /E /Y /R /F /H "%tempDllPath%\*" C:\CNTRLPTS\
set "rc=%ERRORLEVEL%"
call :Trace "After xcopy ActiveX files rc=%rc%"
if ERRORLEVEL 1 (
	goto ROLLBACKDLL
)

>>"%LogFile%" echo Finish Copy files
goto UPDATEOCTOPUS

:ROLLBACKDLL
>>"%LogFile%" echo Some File is locked by other, update cancelled.
call :Trace "ROLLBACKDLL: copying backups from %tempBakPath% to C:\CNTRLPTS\"
copy "%tempBakPath%\*.*" C:\CNTRLPTS\ >>"%TraceLog%" 2>&1
set "rc=%ERRORLEVEL%"
call :Trace "ROLLBACKDLL copy rc=%rc%"

rem ############ Octopus Daily ####################
:UPDATEOCTOPUS
set "octNewPath=C:\CNTRLPTS\OctopusDaily\"
if exist "%octNewPath%" (
	>>"%LogFile%" echo Start update OctopusDaily
	call :Trace "Before Octopus temp cleanup"
	del "%tempOctPath%" /S /Q >>"%TraceLog%" 2>&1
	set "rc=%ERRORLEVEL%"
	call :Trace "After Octopus temp cleanup rc=%rc%"
	>"%GetOctScript%" echo cd OctopusDaily
	>>"%GetOctScript%" echo lcd %tempOctPath%
	>>"%GetOctScript%" echo mget -r *
	>>"%GetOctScript%" echo bye
	call :Trace "Before SFTP get OctopusDaily"
	>>"%LogFile%" "%sFtpPath%" -i "%sFtpKeyPath%" -b "%GetOctScript%" %ftpuser%@%ftphost% < "%AwsFilePath%"
	set "rc=%ERRORLEVEL%"
	call :Trace "After SFTP get OctopusDaily rc=%rc%"

	call :Trace "Before xcopy OctopusDaily"
	>>"%LogFile%" xcopy /E /Y /R /F /H "%tempOctPath%\*" "%octNewPath%"
	set "rc=%ERRORLEVEL%"
	call :Trace "After xcopy OctopusDaily rc=%rc%"
	>>"%LogFile%" echo Finish update OctopusDaily
) else (
	call :Trace "OctopusDaily path missing: %octNewPath%"
)

goto END

:END
>>"%LogFile%" echo Start BridgeService
call :Trace "Before net start BridgeServiceForDCS"
>>"%LogFile%" net start "BridgeServiceForDCS"
set "rc=%ERRORLEVEL%"
call :Trace "After net start BridgeServiceForDCS rc=%rc%"
>>"%LogFile%" echo End
>>"%LogFile%" echo.
call :Trace "Cleaning up scratch/temp files"
del /q "%ScratchFile%" >>"%TraceLog%" 2>&1
del /q "%tempFtpScript%" "%GetVerNumScript%" "%GetDllScript%" "%GetOctScript%" >>"%TraceLog%" 2>&1
rmdir /s /q "%SftpDir%\temp\%RunId%" >>"%TraceLog%" 2>&1
call :Trace "Script completed"
exit /b 0

:Trace
>>"%TraceLog%" echo [%DATE% %TIME%] %~1
exit /b 0

:ReadFirstMatch
set "ReadFile=%~1"
set "ReadPattern=%~2"
set "ReadVar=%~3"
call :Trace "Before findstr %ReadPattern% from %ReadFile%"
if exist "%ReadFile%" (
	findstr /C:"%ReadPattern%" "%ReadFile%" >"%ScratchFile%" 2>>"%TraceLog%"
	set "rc=%ERRORLEVEL%"
) else (
	set "rc=missing"
	>"%ScratchFile%" echo.
)
call :Trace "After findstr %ReadPattern% rc=%rc%"
set "%ReadVar%="
set /p %ReadVar%=<"%ScratchFile%" 2>nul
call :Trace "After reading %ReadVar% value=!%ReadVar%!"
exit /b 0

:UploadFile
set "UploadSource=%~1"
set "UploadCopy=%~2"
set "UploadName=%~3"
call :Trace "Before copy %UploadName% source=%UploadSource% copy=%UploadCopy%"
copy "%UploadSource%" "%UploadCopy%" >>"%TraceLog%" 2>&1
set "rc=%ERRORLEVEL%"
call :Trace "After copy %UploadName% rc=%rc%"
>"%tempFtpScript%" echo cd %ActnUploadDir%
>>"%tempFtpScript%" echo put %UploadCopy%
>>"%tempFtpScript%" echo bye
call :Trace "Before SFTP upload %UploadName%"
>>"%LogFile%" "%sFtpPath%" -i "%sFtpKeyPath%" -b "%tempFtpScript%" %ftpuser%@%ftphost% < "%AwsFilePath%"
set "rc=%ERRORLEVEL%"
call :Trace "After SFTP upload %UploadName% rc=%rc%"
del /q "%UploadCopy%" >>"%TraceLog%" 2>&1
set "rc=%ERRORLEVEL%"
call :Trace "Deleted upload copy %UploadName% rc=%rc%"
del /q "%tempFtpScript%" >>"%TraceLog%" 2>&1
set "rc=%ERRORLEVEL%"
call :Trace "Deleted FTP script %UploadName% rc=%rc%"
exit /b 0
