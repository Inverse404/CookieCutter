del BtkVersion.h
del build.version
FOR /F delims^=^" %%A IN ('"git describe --dirty --tags"') DO echo "%%A" > build.version
copy BtkVersionTemplate.h + build.version BtkVersion.h
