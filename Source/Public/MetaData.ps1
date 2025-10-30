# dotnet add package TagLibSharp --version 2.3.0

# Install the NuGet package provider if not already present
#Find-PackageProvider -Name NuGet | Install-PackageProvider -Force
# Register nuget.org as a package source if not already registered
#Register-PackageSource -Name nuget.org -Location https://www.nuget.org/api/v2 -ProviderName NuGet
# Download and extract TagLibSharp to a specified folder
# Replace 'path\to\folder' with your desired location
#Find-Package -ProviderName NuGet -Name TagLibSharp | Install-Package -Destination path\to\folder
#Install-Package -ProviderName NuGet -Name TagLibSharp

$path = "C:\Users\dsmith14\OneDrive - WellSpan Health\Documents\GitHub\dps\wood"
$Files = Get-ChildItem $path -File
$allMetaData = @()

foreach ($file in $files) {
	$shell = New-Object -COMObject Shell.Application
	$folder = Split-Path $file
	$fileName = Split-Path $file -Leaf
	$fileFullName = $file.FullName
	#$shellfolder = $shell.Namespace($folder)
	#$shellfile = $shellfolder.ParseName($fileName)
	$ShellFolder = $shell.Namespace($file.Directory.FullName)
    $ShellFile = $ShellFolder.ParseName($file.Name)
	
	$fileFullName
	$MetaDataProperties = [ordered] @{}
	$hash = [ordered]@{}
    0..400 | ForEach-Object -Process {
        $DataValue = $shellFolder.GetDetailsOf($null, $_)
        $PropertyValue = (Get-Culture).TextInfo.ToTitleCase($DataValue.Trim()).Replace(' ', '')
        if ($PropertyValue -ne '') {
          $MetaDataProperties["$_"] = $PropertyValue
		  $hash[$PropertyValue] = $_
        }
    }
	$hashSorted = $hash.GetEnumerator()|sort key
	
	$metaValues = @("Name", "Title", "Subject", "Tags", "Categories", "Comments", "ContentStatus", "ContentType")
	$keys = foreach ($m in $metaValues) {$hash[$m]}
	
	$MetaDataObject = [ordered] @{}
	$MetaDataObject["FileFullName"] = $fileFullName
	$MetaDataObject["FileName"] = $fileName
	$MetaDataObject["Folder"] = $folder
	foreach ($Key in $keys) {   #$MetaDataProperties.Keys) {
        $Property = $MetaDataProperties[$Key]
        $Value = $ShellFolder.GetDetailsOf($ShellFile, [int] $Key)
        if ($Property -in 'Attributes', 'Folder', 'Type', 'SpaceFree', 'TotalSize', 'SpaceUsed') {
          #continue
        }
        If (($null -ne $Value) -and ($Value -ne '')) {
          $MetaDataObject["$Property"] = $Value
        }
    }

	$MetaDataObject["CreationTime"] = $file.CreationTime
	$MetaDataObject["LastAccessTime"] = $file.LastAccessTime
	$MetaDataObject["LastWriteTime"] = $file.LastWriteTime
	$MetaDataObject
	
	$allMetaData += $MetaDataObject
}

