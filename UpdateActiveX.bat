@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ############ Start Clean Temp Files ################
set "BootstrapLog=C:\CNTRLPTS\Util\log\activeXDaily_startup.log"
if not exist "C:\CNTRLPTS\Util\log\" mkdir "C:\CNTRLPTS\Util\log\" 2>nul
>>"%BootstrapLog%" echo [%DATE% %TIME%] Starting %~nx0 from "%CD%" as %USERNAME%
pushd "%~dp0" || (
	>>"%BootstrapLog%" echo [%DATE% %TIME%] ERROR: failed to change to script folder "%~dp0".
	exit /b 1
)
set "ScratchFile=C:\CNTRLPTS\Util\log\UpdateActiveX_%COMPUTERNAME%_%RANDOM%_%RANDOM%.tmp"
if not exist ".\sftp\temp\" mkdir ".\sftp\temp\" 2>nul
rem ############ Finish Clean Temp Files ################

rem ############ Start Workstation Logging ################

rem # retrieve current date/time in a locale-independent format
for /f "tokens=1-7" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Date -Format 'yyyy MM dd HH mm ss yyyyMMdd'" 2^>nul') do (
	set "yyyy=%%A"
	set "mm=%%B"
	set "dd=%%C"
	set "hh=%%D"
	set "mi=%%E"
	set "ss=%%F"
	set "yyyymmdd=%%G"
)
if not defined yyyymmdd (
	>>"%BootstrapLog%" echo [%DATE% %TIME%] ERROR: failed to read current date/time.
	exit /b 1
)
set /a mx=1%mm%-100
set /a dx=1%dd%-100
set "RunId=%yyyy%%mm%%dd%%hh%%mi%%ss%_%RANDOM%"

set LogFile=C:\CNTRLPTS\Util\log\activeXDaily_%yyyy%%mm%%dd%.log
>>%LogFile% echo 
>>%LogFile% echo [%DATE% %TIME%] Startup completed. Scratch file: %ScratchFile%

>>%LogFile% echo Get current version

rem # retrieve current ActiveX version
set /p ver=<C:\CNTRLPTS\Version.txt

>>%LogFile% echo Get Control Point
rem # retrieve control point code
findstr /C:CNTRL_PT_CD C:\CNTRLPTS\dc.ini > "%ScratchFile%"
set /p cntpnt=<"%ScratchFile%"

>>%LogFile% echo Get Host
rem # retrieve workstation name
hostname > "%ScratchFile%"
set /p pc_name=<"%ScratchFile%"

>>%LogFile% echo Get ip
rem # retrieve workstation ip
set "ip="
FOR /F "TOKENS=1,2 DELIMS=:" %%A IN ('ipconfig ^| findstr /C:IPv4') DO if not defined ip set "ip=%%B"
for /l %%a in (1,1,150) do if "!ip:~0,1!"==" " set "ip=!ip:~1!"

>>%LogFile% echo Get Operation Type
rem # retrieve operation mode
findstr /C:ACCESS_DCO C:\CNTRLPTS\dc.ini > "%ScratchFile%"
set /p isDCO=<"%ScratchFile%"

>>%LogFile% echo Get Webcam Availability
rem # retrieve operation mode
findstr /C:CAM_ENABLED C:\CNTRLPTS\dc.ini > "%ScratchFile%"
set /p hasCam=<"%ScratchFile%"

>>%LogFile% echo Read Config
rem # retrieve ftp info
findstr /C:REMOTE_SERVER_IP C:\CNTRLPTS\Util\psftpSetting.txt > "%ScratchFile%"
set /p x=<"%ScratchFile%"

rem # modify server ip
set dt=%yyyy%_%mm%_%dd%__%hh%_%mi%_%ss%
>>%LogFile% echo current date: %dt%
set fromdt=2023_10_30__16_03_00
>>%LogFile% echo Using new server ip from %fromdt%
if %dt% gtr %fromdt% (
set x=%x:uatint=uat.int%
)
echo using server ip: %x%
rem #

@echo %x:~17% > "%ScratchFile%"
set /p ftphost=<"%ScratchFile%"
findstr /C:REMOTE_USER C:\CNTRLPTS\Util\psftpSetting.txt > "%ScratchFile%"
set /p x=<"%ScratchFile%"
rem # modify server user
if %dt% gtr %fromdt% (
set x=%x:2=1%
)
rem #
@echo %x:~12% > "%ScratchFile%"
set /p ftpuser=<"%ScratchFile%"
for /l %%a in (1,1,150) do if "!ftpuser:~-1!"==" " set ftpuser=!ftpuser:~0,-1!
findstr /C:REMOTE_KEY C:\CNTRLPTS\Util\psftpSetting.txt > "%ScratchFile%"
set /p x=<"%ScratchFile%"
rem # modify server key
if %dt% gtr %fromdt% (
set x=%x:2=1%
)
rem # 
@echo %x:~11% > "%ScratchFile%"
set /p ftpkey=<"%ScratchFile%"
del /q "%ScratchFile%" 2>nul

set sFtpPath=C:\CNTRLPTS\Util\sftp\psftp
set tempFtpScript=C:\CNTRLPTS\Util\sftp\%RunId%.ftp
set ActnFilePath=C:\CNTRLPTS\Util\sftp\%pc_name%_%RunId%.updateActiveXLog
set AwsFilePath=C:\CNTRLPTS\Util\sftp\alwaysYes.txt
set sFtpKeyPath=C:\CNTRLPTS\Util\sftp\%ftpkey%
set ActnUploadDir=/Log/

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
set GetVerNumScript=C:\CNTRLPTS\Util\sftp\%RunId%_getVersionNum.ftp
set GetDllScript=C:\CNTRLPTS\Util\sftp\%RunId%_getLatestDll.ftp
set GetOctScript=C:\CNTRLPTS\Util\sftp\%RunId%_getLatestOct.ftp
set tempBakPath=C:\CNTRLPTS\Util\sftp\temp\%RunId%\bak\
set tempDllPath=C:\CNTRLPTS\Util\sftp\temp\%RunId%\dll\
set tempOctPath=C:\CNTRLPTS\Util\sftp\temp\%RunId%\oct\

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
del /q "%ScratchFile%" 2>nul
if defined RunId rmdir /s /q "C:\CNTRLPTS\Util\sftp\temp\%RunId%" 2>nul
popd