REM Pulls the hard drive model from wmic, checks the included lists to determine if it is a HDD or SSD and saves it to UDF14.

wmic diskdrive get model | findstr /v "USB" | findstr /v "Model" | findstr /r "." > tmpfile
set /p VAR= < tmpfile
find /v /c "" tmpfile | findstr /r "." > tmpfile2
set /p MULTI= < tmpfile2
if "%multi%" NEQ "---------- TMPFILE: 1" SET MULTI=Multiple Drives
echo %MULTI%
del tmpfile
del tmpfile2


SETLOCAL ENABLEDELAYEDEXPANSION  
SET NAME=%VAR%	
ECHO "%NAME%"
CALL :TRIM NAME
ECHO "%NAME%"
if "%MULTI%"=="Multiple Drives" goto :MULTI
GOTO :HDDTEST
GOTO :EOF

:TRIM
SetLocal EnableDelayedExpansion
Call :TRIMSUB %%%1%%
EndLocal & set %1=%tempvar%
GOTO :EOF

:TRIMSUB
set tempvar=%*
GOTO :EOF


:HDDTEST
find "%NAME%" hdd.lst
	set ERRLVL=%errorlevel%
	if %ERRLVL%==1 GOTO :SSDTEST
	if %ERRLVL%==0 GOTO :HDD
GOTO :EOF

:SSDTEST
find "%NAME%" ssd.lst
	set ERRLVL=%errorlevel%
	if %ERRLVL%==1 GOTO :UNKNOWN
	if %ERRLVL%==0 GOTO :SSD
GOTO :EOF

:HDD
Echo Device is a HDD.
powershell New-ItemProperty -Path HKLM:\SOFTWARE\CentraStage\ -Name "Custom14" -PropertyType String -Value "'HDD'"
GOTO :EOF

:SSD
Echo Device is a SSD.
powershell New-ItemProperty -Path HKLM:\SOFTWARE\CentraStage\ -Name "Custom14" -PropertyType String -Value "'SSD'"
GOTO :EOF

:UNKNOWN
Echo Device type is unknown.
powershell New-ItemProperty -Path HKLM:\SOFTWARE\CentraStage\ -Name "Custom14" -PropertyType String -Value "'%NAME%'"
GOTO :EOF

:MULTI
echo Multiple drives detected.
powershell New-ItemProperty -Path HKLM:\SOFTWARE\CentraStage\ -Name "Custom14" -PropertyType String -Value "'%MULTI%'"
GOTO :EOF

:EOF