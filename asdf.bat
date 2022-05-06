"C:\Program Files (x86)\digiCamControl\CameraControlRemoteCmd.exe" /c set session.folder C:\Users\Fablab\tmp
"C:\Program Files (x86)\digiCamControl\CameraControlRemoteCmd.exe" /c set session.filenametemplate capture1
"C:\Program Files (x86)\digiCamControl\CameraControlRemoteCmd.exe" /c capture

timeout /t 3

set source="C:\Users\Fablab\tmp"
set target="C:\Users\Fablab\capture\cap.jpg"

FOR /F "delims=" %%I IN ('DIR %source%\*.jpg /A:-D /O:-D /B') DO COPY %source%\"%%I" %target% & echo %%I & GOTO :END
:END

