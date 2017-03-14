@echo off
	rem The package folder can be downloaded anywhere (inside a temp folder)
	rem usually it's the ArtifactsRoot\packages\minlab folder.
	rem Once the package has been downloaded, this file should be run. This
	rem file (unpack.bat) automatically installs the package.

	rem assumes argument to CD is passed as arg1 to this file (where the package
	rem has been downloaded)

set base_path=%~1
echo path provided '%base_path%'

echo removing directory "%base_path%\spec"
rmdir /s /q "%base_path%\spec"

echo removing directory "%base_path%\docs"
rmdir /s /q "%base_path%\docs"

echo deleting "%base_path%\.rspec"
del "%base_path%\.rspec"

echo copying "%base_path%/lib" to "%base_path%"
xcopy /s "%base_path%/lib" "%base_path%"


set env_load_script="%base_path%\paths.txt"
echo creating environment script '%env_load_script%'
echo %base_path% > %env_load_script%

echo done.