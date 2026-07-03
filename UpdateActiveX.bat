@echo off
setlocal enabledelayedexpansion
set EarlyLog=C:\CNTRLPTS\Util\log\activeXDaily_startup_trace.log
if not exist C:\CNTRLPTS\Util\log\ mkdir C:\CNTRLPTS\Util\log\ 2>nul
>>%EarlyLog% echo ==================================================
>>%EarlyLog% echo [%DATE% %TIME%] Script starting
>>%EarlyLog% echo User=%USERNAME% Computer=%COMPUTERNAME% Session=%SESSIONNAME%
>>%EarlyLog% echo ScriptPath=%~f0 ScriptDir=%~dp0 CurrentDir=%CD%
>>%EarlyLog% echo CmdLine=%CMDCMDLINE%

rem ############ Start Clean Temp Files ################
>>%EarlyLog% echo [%DATE% %TIME%] Before cd to script folder
cd %~dp0
>>%EarlyLog% echo [%DATE% %TIME%] After cd, errorlevel=%ERRORLEVEL%, CurrentDir=%CD%
>>%EarlyLog% echo [%DATE% %TIME%] Before drive switch to %~d0
call %~d0
>>%EarlyLog% echo [%DATE% %TIME%] After drive switch, errorlevel=%ERRORLEVEL%, CurrentDir=%CD%
>>%EarlyLog% echo [%DATE% %TIME%] Before temp cleanup
del .\sftp\temp\* /S /Q
>>%EarlyLog% echo [%DATE% %TIME%] After temp file cleanup, errorlevel=%ERRORLEVEL%
for /d %%i in (.\sftp\temp\*) do rmdir /s /q "%%i" 
>>%EarlyLog% echo [%DATE% %TIME%] After temp folder cleanup, errorlevel=%ERRORLEVEL%
rem ############ Finish Clean Temp Files ################

rem ############ Start Workstation Logging ################

rem # retrieve current date
>>%EarlyLog% echo [%DATE% %TIME%] Before DATE/T parse
FOR /F "TOKENS=1,2 DELIMS= " %%A IN ('DATE/T') DO (
	set x=%%A
	set y=%%B
)
>>%EarlyLog% echo [%DATE% %TIME%] After DATE/T parse, errorlevel=%ERRORLEVEL%, x=%x%, y=%y%
>>%EarlyLog% echo [%DATE% %TIME%] Before first write to scratch file a
echo %x% | findstr /C:/ > a
>>%EarlyLog% echo [%DATE% %TIME%] After first write to a, errorlevel=%ERRORLEVEL%
set /p d1=<a
>>%EarlyLog% echo [%DATE% %TIME%] After read d1 from a, errorlevel=%ERRORLEVEL%, d1=%d1%
echo %y% | findstr /C:/ > a
>>%EarlyLog% echo [%DATE% %TIME%] After second write to a, errorlevel=%ERRORLEVEL%
set /p d2=<a
>>%EarlyLog% echo [%DATE% %TIME%] After read d2 from a, errorlevel=%ERRORLEVEL%, d2=%d2%
if not x%d1%==x (
	set d=%d1%
)
if not x%d2%==x (
	set d=%d2%
)
>>%EarlyLog% echo [%DATE% %TIME%] Selected date token d=%d%

@echo %d% > a
>>%EarlyLog% echo [%DATE% %TIME%] Wrote selected date token to a, errorlevel=%ERRORLEVEL%
FOR /F "TOKENS=1,2,3 eol=/ DELIMS=/ " %%A IN ('type a') DO (
	set dd=%%A
	set mm=%%B
	set yyyy=%%C
)
>>%EarlyLog% echo [%DATE% %TIME%] Parsed date parts yyyy=%yyyy%, mm=%mm%, dd=%dd%, errorlevel=%ERRORLEVEL%

set mx=%mm:/0=/%
set mx=%mm:~1%
set dx=%dd:/0=/%
set dx=%dd:~1%
>>%EarlyLog% echo [%DATE% %TIME%] Initial mx=%mx%, dx=%dx%

if %mm% gtr 9 (
	set mx=%mm%
)
if %dd% gtr 9 (
	set dx=%dd%
)
>>%EarlyLog% echo [%DATE% %TIME%] Final mx=%mx%, dx=%dx%

rem # retrieve current time
>>%EarlyLog% echo [%DATE% %TIME%] Before TIME/T parse
FOR /F "TOKENS=1 eol=: DELIMS=: " %%A IN ('TIME/T') DO SET hh=%%A
FOR /F "TOKENS=2 eol=: DELIMS=: " %%A IN ('TIME/T') DO SET mi=%%A
>>%EarlyLog% echo [%DATE% %TIME%] Parsed time hh=%hh%, mi=%mi%, errorlevel=%ERRORLEVEL%

set LogFile=C:\CNTRLPTS\Util\log\activeXDaily_%yyyy%%mm%%dd%.log
>>%EarlyLog% echo [%DATE% %TIME%] LogFile resolved to %LogFile%
>>%LogFile% echo 
>>%LogFile% echo Startup trace log: %EarlyLog%

>>%LogFile% echo Get current version
>>%EarlyLog% echo [%DATE% %TIME%] Before reading Version.txt

rem # retrieve current ActiveX version
set /p ver=<C:\CNTRLPTS\Version.txt
>>%EarlyLog% echo [%DATE% %TIME%] After reading Version.txt, errorlevel=%ERRORLEVEL%, ver=%ver%

>>%LogFile% echo Get Control Point
rem # retrieve control point code
>>%EarlyLog% echo [%DATE% %TIME%] Before reading CNTRL_PT_CD from dc.ini
findstr /C:CNTRL_PT_CD C:\CNTRLPTS\dc.ini > a
>>%EarlyLog% echo [%DATE% %TIME%] After findstr CNTRL_PT_CD, errorlevel=%ERRORLEVEL%
set /p cntpnt=<a
>>%EarlyLog% echo [%DATE% %TIME%] After reading cntpnt, errorlevel=%ERRORLEVEL%, cntpnt=%cntpnt%

>>%LogFile% echo Get Host
rem # retrieve workstation name
>>%EarlyLog% echo [%DATE% %TIME%] Before hostname
hostname > a
>>%EarlyLog% echo [%DATE% %TIME%] After hostname, errorlevel=%ERRORLEVEL%
set /p pc_name=<a
>>%EarlyLog% echo [%DATE% %TIME%] After reading pc_name, errorlevel=%ERRORLEVEL%, pc_name=%pc_name%

>>%LogFile% echo Get ip
rem # retrieve workstation ip
>>%EarlyLog% echo [%DATE% %TIME%] Before ipconfig IPv4 lookup
ipconfig | findstr /C:IPv4 > a
>>%EarlyLog% echo [%DATE% %TIME%] After ipconfig IPv4 lookup, errorlevel=%ERRORLEVEL%
FOR /F "TOKENS=1,2 DELIMS=:" %%A IN ('type a') DO @<nul set /p "=%%B " > a
>>%EarlyLog% echo [%DATE% %TIME%] After IP parse rewrite to a, errorlevel=%ERRORLEVEL%
set /p ip=<a
>>%EarlyLog% echo [%DATE% %TIME%] After reading ip, errorlevel=%ERRORLEVEL%, ip=%ip%

>>%LogFile% echo Get Operation Type
rem # retrieve operation mode
>>%EarlyLog% echo [%DATE% %TIME%] Before reading ACCESS_DCO from dc.ini
findstr /C:ACCESS_DCO C:\CNTRLPTS\dc.ini > a
>>%EarlyLog% echo [%DATE% %TIME%] After findstr ACCESS_DCO, errorlevel=%ERRORLEVEL%
set /p isDCO=<a
>>%EarlyLog% echo [%DATE% %TIME%] After reading isDCO, errorlevel=%ERRORLEVEL%, isDCO=%isDCO%

>>%LogFile% echo Get Webcam Availability
rem # retrieve operation mode
>>%EarlyLog% echo [%DATE% %TIME%] Before reading CAM_ENABLED from dc.ini
findstr /C:CAM_ENABLED C:\CNTRLPTS\dc.ini > a
>>%EarlyLog% echo [%DATE% %TIME%] After findstr CAM_ENABLED, errorlevel=%ERRORLEVEL%
set /p hasCam=<a
>>%EarlyLog% echo [%DATE% %TIME%] After reading hasCam, errorlevel=%ERRORLEVEL%, hasCam=%hasCam%

>>%LogFile% echo Read Config
rem # retrieve ftp info
>>%EarlyLog% echo [%DATE% %TIME%] Before reading REMOTE_SERVER_IP from psftpSetting.txt
findstr /C:REMOTE_SERVER_IP C:\CNTRLPTS\Util\psftpSetting.txt > a
>>%EarlyLog% echo [%DATE% %TIME%] After findstr REMOTE_SERVER_IP, errorlevel=%ERRORLEVEL%
set /p x=<a
>>%EarlyLog% echo [%DATE% %TIME%] After reading REMOTE_SERVER_IP line, errorlevel=%ERRORLEVEL%, x=%x%

rem # modify server ip
set dt=%DATE:~6,4%_%DATE:~3,2%_%DATE:~0,2%__%TIME:~0,2%_%TIME:~3,2%_%TIME:~6,2%
set dt=%dt: =0%
>>%EarlyLog% echo [%DATE% %TIME%] Computed dt=%dt%
>>%LogFile% echo current date: %dt%
set fromdt=2023_10_30__16_03_00
>>%LogFile% echo Using new server ip from %fromdt%
if %dt% gtr %fromdt% (
set x=%x:uatint=uat.int%
)
>>%EarlyLog% echo [%DATE% %TIME%] After server ip date adjustment, x=%x%
echo using server ip: %x%
rem #

@echo %x:~17% > a
>>%EarlyLog% echo [%DATE% %TIME%] After writing ftphost to a, errorlevel=%ERRORLEVEL%
set /p ftphost=<a
>>%EarlyLog% echo [%DATE% %TIME%] After reading ftphost, errorlevel=%ERRORLEVEL%, ftphost=%ftphost%
findstr /C:REMOTE_USER C:\CNTRLPTS\Util\psftpSetting.txt > a
>>%EarlyLog% echo [%DATE% %TIME%] After findstr REMOTE_USER, errorlevel=%ERRORLEVEL%
set /p x=<a
>>%EarlyLog% echo [%DATE% %TIME%] After reading REMOTE_USER line, errorlevel=%ERRORLEVEL%, x=%x%
rem # modify server user
if %dt% gtr %fromdt% (
set x=%x:2=1%
)
rem #
@echo %x:~12% > a
>>%EarlyLog% echo [%DATE% %TIME%] After writing ftpuser to a, errorlevel=%ERRORLEVEL%
set /p ftpuser=<a
for /l %%a in (1,1,150) do if "!ftpuser:~-1!"==" " set ftpuser=!ftpuser:~0,-1!
>>%EarlyLog% echo [%DATE% %TIME%] After reading ftpuser, errorlevel=%ERRORLEVEL%, ftpuser=%ftpuser%
findstr /C:REMOTE_KEY C:\CNTRLPTS\Util\psftpSetting.txt > a
>>%EarlyLog% echo [%DATE% %TIME%] After findstr REMOTE_KEY, errorlevel=%ERRORLEVEL%
set /p x=<a
>>%EarlyLog% echo [%DATE% %TIME%] After reading REMOTE_KEY line, errorlevel=%ERRORLEVEL%
rem # modify server key
if %dt% gtr %fromdt% (
set x=%x:2=1%
)
rem # 
@echo %x:~11% > a
>>%EarlyLog% echo [%DATE% %TIME%] After writing ftpkey to a, errorlevel=%ERRORLEVEL%
set /p ftpkey=<a
>>%EarlyLog% echo [%DATE% %TIME%] After reading ftpkey, errorlevel=%ERRORLEVEL%, ftpkey=%ftpkey%
del /q a
>>%EarlyLog% echo [%DATE% %TIME%] After deleting scratch file a, errorlevel=%ERRORLEVEL%

set sFtpPath=C:\CNTRLPTS\Util\sftp\psftp
set tempFtpScript=C:\CNTRLPTS\Util\sftp\%yyyy%%mm%%dd%%hh%%mi%.ftp
set ActnFilePath=C:\CNTRLPTS\Util\sftp\%pc_name%_%yyyy%%mm%%dd%.updateActiveXLog
set AwsFilePath=C:\CNTRLPTS\Util\sftp\alwaysYes.txt
set sFtpKeyPath=C:\CNTRLPTS\Util\sftp\%ftpkey%
set ActnUploadDir=/Log/
>>%EarlyLog% echo [%DATE% %TIME%] SFTP variables resolved: sFtpPath=%sFtpPath%, tempFtpScript=%tempFtpScript%, ActnFilePath=%ActnFilePath%

rem cd %sFtpPath%
>>%LogFile% echo Call ftp for update log
>>%ActnFilePath% echo -----------------------------------
>>%ActnFilePath% echo %yyyy%-%mm%-%dd% %hh%:%mi%
>>%ActnFilePath% echo %pc_name%
>>%ActnFilePath% echo %ip%
>>%ActnFilePath% echo %cntpnt%
>>%ActnFilePath% echo %ver%
>>%ActnFilePath% echo %isDCO%
>>%ActnFilePath% echo %hasCam%
>>%ActnFilePath% dir /ad /d C:\CNTRLPTS\
>>%ActnFilePath% dir /ad /d C:\CCS\
>>%ActnFilePath% echo -----------------------------------

> %tempFtpScript% echo cd %ActnUploadDir%
>> %tempFtpScript% echo put %ActnFilePath%
>> %tempFtpScript% echo bye

rem # send via sftp
>>%LogFile% %sFtpPath% -i %sFtpKeyPath% -b %tempFtpScript% %ftpuser%@%ftphost% < %AwsFilePath%

del /q %ActnFilePath%
del /q %tempFtpScript%

rem ############ Finish Workstation Logging ################


rem ############ Get Daily ActiveX Log ################
set logFilePath=C:\CNTRLPTS\Util\sftp\%pc_name%_%yyyy%%mm%%dd%%hh%.ActiveXLog
set logEPSPath=C:\CNTRLPTS\Util\sftp\%pc_name%_%yyyy%%mm%%dd%.EPSLog
set logSrcPath=C:\CNTRLPTS\Log\DCSPeripheryCOM_%yyyy%%mm%%dd%.log
set epsSrcPath=C:\CNTRLPTS\Log\%yyyy%-%mx%-%dx%.log
set logSrcPath=C:\CNTRLPTS\Log\DCSPeripheryCOM_%yyyy%%mm%%dd%.log
rem for BridgeService Log
set "logBridgeServiceSrcFile="
    for /f "delims=" %%a in ('dir /b /o-d "C:\CNTRLPTS\Log\BridgeService*.log" 2^>nul') do (
        if not defined logBridgeServiceSrcFile set "logBridgeServiceSrcFile=%%a"
    )
>>%LogFile% echo file %logBridgeServiceSrcFile%
set logBridgeServiceSrcPath=C:\CNTRLPTS\Log\%logBridgeServiceSrcFile%
set logBridgeServicPath=C:\CNTRLPTS\Util\sftp\%pc_name%_%logBridgeServiceSrcFile%

rem restart BridgeService
>>%LogFile% echo Stop BridgeService (Restart)
>>%LogFile% net stop "BridgeServiceForDCS"

if not "%isDCO%" equ "" (
rem	if "%isDCO%" equ "ACCESS_DCO=1" (
		if EXIST %logSrcPath% (
			>>%LogFile% echo Send ActiveX Com Log
			copy %logSrcPath% %logFilePath%

			> %tempFtpScript% echo cd %ActnUploadDir%
			>> %tempFtpScript% echo put %logFilePath%
			>> %tempFtpScript% echo bye
			>>%LogFile% %sFtpPath% -i %sFtpKeyPath% -b %tempFtpScript% %ftpuser%@%ftphost% < %AwsFilePath%

			del /q %logFilePath%
			del /q %tempFtpScript%
		)

		if EXIST %epsSrcPath% (
			>>%LogFile% echo Send EPS Log
			copy %epsSrcPath% %logEPSPath%

			> %tempFtpScript% echo cd %ActnUploadDir%
			>> %tempFtpScript% echo put %logEPSPath%
			>> %tempFtpScript% echo bye
			>>%LogFile% %sFtpPath% -i %sFtpKeyPath% -b %tempFtpScript% %ftpuser%@%ftphost% < %AwsFilePath%
			
			del /q %logEPSPath%
			del /q %tempFtpScript%
		)
		if "%logBridgeServiceSrcFile%" neq "" (
			>>%LogFile% echo Send Bridge Service Log
			copy %logBridgeServiceSrcPath% %logBridgeServicPath%

			> %tempFtpScript% echo cd %ActnUploadDir%
			>> %tempFtpScript% echo put %logBridgeServicPath%
			>> %tempFtpScript% echo bye
			>>%LogFile% %sFtpPath% -i %sFtpKeyPath% -b %tempFtpScript% %ftpuser%@%ftphost% < %AwsFilePath%

			del /q %logBridgeServicPath%
			del /q %tempFtpScript%
		)
rem	)
)
rem ############ Finish Daily ActiveX Log ################


rem ############ Core Update ActiveX ################

set tempVerNumFile=C:\CNTRLPTS\Util\Version.txt
set GetVerNumScript=C:\CNTRLPTS\Util\sftp\getVersionNum.ftp
set GetDllScript=C:\CNTRLPTS\Util\sftp\getLatestDll.ftp
set GetOctScript=C:\CNTRLPTS\Util\sftp\getLatestOct.ftp
set tempBakPath=C:\CNTRLPTS\Util\sftp\temp\bak\
set tempDllPath=C:\CNTRLPTS\Util\sftp\temp\dll\
set tempOctPath=C:\CNTRLPTS\Util\sftp\temp\oct\

rem cd ..
if EXIST %tempVerNumFile% (
	del /q %tempVerNumFile%
)

if NOT EXIST %tempDllPath% (
	mkdir %tempDllPath%
)
if NOT EXIST %tempOctPath% (
	mkdir %tempOctPath%
)
if NOT EXIST %tempBakPath% (
	mkdir %tempBakPath%
)

rem ############ Start Get Server Version ################
>>%LogFile% echo Call ftp for version num

> %GetVerNumScript% echo cd CNTRLPTS
>> %GetVerNumScript% echo lcd C:\CNTRLPTS\Util\
>> %GetVerNumScript% echo mget Version.txt
>> %GetVerNumScript% echo bye

>>%LogFile% %sFtpPath% -i %sFtpKeyPath% -b %GetVerNumScript% %ftpuser%@%ftphost% < %AwsFilePath%
del /q %GetVerNumScript%
set /p nVer=<%tempVerNumFile%

rem ############ Finish Get Server Version ################


rem ############ Start Compare Server Version ################

if EXIST %tempVerNumFile% (
	>>%LogFile% echo Current version : %ver%
	>>%LogFile% echo Latest version : %nVer%
	if "%nVer%" == "%ver%" (
		>>%LogFile% echo Current version is latest, no need update
		GOTO END
	) ELSE (
		>>%LogFile% echo Current version is NOT latest, start update
	)
) ELSE (
	>>%LogFile% echo Get latest version failed
	GOTO END
)
rem ############ Done Compare Server Version ################

rem ############ Start Get latest ActiveX file ################

>>%LogFile% echo Call ftp for latest activeX file

> %GetDllScript% echo cd CNTRLPTS
>> %GetDllScript% echo lcd %tempDllPath%
>> %GetDllScript% echo mget -r *
>> %GetDllScript% echo bye

>>%LogFile% %sFtpPath% -i %sFtpKeyPath% -b %GetDllScript% %ftpuser%@%ftphost% < %AwsFilePath%

rem ############ Finish Get latest ActiveX file ################


rem ############ Check ActiveX file ################
>>%LogFile% echo backup current file 
for /f "delims=" %%f in ('dir %tempDllPath% /b /a-d-h-s') do (
	set fname=C:\CNTRLPTS\%%f
	if exist !fname! (
		copy !fname! %tempBakPath%
	)
)

rem ############ Update current ActiveX file to latest ################
>>%LogFile% echo Copy files
>>%LogFile% xcopy /E /Y /R /F /H %tempDllPath%\* C:\CNTRLPTS\
if ERRORLEVEL 1 (
	GOTO ROLLBACKDLL
)

>>%LogFile% echo Finish Copy files
GOTO UPDATEOCTOPUS

:ROLLBACKDLL
>>%LogFile% echo Some File is locked by other, update cancelled.
copy %tempBakPath%\*.* C:\CNTRLPTS\

rem ############ Octopus Daily ####################
:UPDATEOCTOPUS
set octNewPath=C:\CNTRLPTS\OctopusDaily\

if EXIST %octNewPath% (
	>>%LogFile% echo Start update OctopusDaily
	del %tempOctPath% /S /Q	
	> %GetOctScript% echo cd OctopusDaily
	>> %GetOctScript% echo lcd %tempOctPath%
	>> %GetOctScript% echo mget -r *
	>> %GetOctScript% echo bye
	>>%LogFile% %sFtpPath% -i %sFtpKeyPath% -b %GetOctScript% %ftpuser%@%ftphost% < %AwsFilePath%

	>>%LogFile% xcopy /E /Y /R /F /H %tempOctPath%\* %octNewPath%
	>>%LogFile% echo Finish update OctopusDaily	
)

GOTO END

:END
>>%LogFile% echo Start BridgeService
>>%LogFile% net start "BridgeServiceForDCS"
>>%LogFile% echo End
>>%LogFile% echo 
>>%EarlyLog% echo [%DATE% %TIME%] Reached END label, errorlevel=%ERRORLEVEL%