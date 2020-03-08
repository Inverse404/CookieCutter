
rmdir /S /Q x64\deploy
mkdir x64\deploy
xcopy x64\Release\CookieCutter.exe x64\deploy
xcopy qtquickcontrols2.conf x64\deploy
xcopy gpl-3.0.txt x64\deploy
xcopy customCookieShapesDefinition.json x64\deploy
call compileTranslationFiles.bat
xcopy *.qm x64\deploy
C:\Qt\5.14.0\msvc2017_64\bin\windeployqt.exe --release --qmldir "." --compiler-runtime --no-virtualkeyboard "x64\deploy\CookieCutter.exe"
