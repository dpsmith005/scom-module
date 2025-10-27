# ModuleBuilder

A template/scaffolding for developing Powershell modules. Invoke ModuleBuilder to output scripts into a Powershell module.

Notes Dan Rupp put together for ModuleBuilder
[Dan Notes](https://rhbldsrc/automation-team/tenable-security-center-module/-/blob/main/Source/README.md?ref_type=heads)

Original code on Github [Module Builder](https://github.com/PoshCode/ModuleBuilder/tree/main) at
[https://github.com/PoshCode/ModuleBuilder/tree/main](https://github.com/PoshCode/ModuleBuilder/tree/main)

## Requirements

Install the ModuleBuilder Powershell module on a development machine or on a CI/CD runner.

```powershell
Install-Module -Name ModuleBuilder
```

```posh
Install-Script -Name Install-RequiredModule
```

## Building the module

1. run `Install-RequiredModule`
2. Add `.ps1` script files to the `Source` folder
3. Run `Build-Module .\Source -SemVer 1.1.7`
4. Compiled module appears in the `Output` folder

## Versioning

ModuleBuilder will automatically apply the next semver version
if you have installed [gitversion](https://gitversion.readthedocs.io/en/latest/).

To manually create a new version run `Build-Module .\Source -SemVer 0.0.2`

## Additional Information

[https://github.com/PoshCode/ModuleBuilder]

Register the local Wellspan repository with your powershell instance

```posh
Register-PSRepository -Name WellspanNuget -SourceLocation  http://tsmgr4.wellspan.org:8080/nuget -PublishLocation  http://tsmgr4.wellspan.org:8080/nuget -InstallationPolicy Trusted
```

List all modules in the WellspanNuget repository

```posh
    Find-Module -Repository WellspanNuget
```

Install a module as you would any other module, specifying the repository

```posh
    Install-Module -Repository WellspanNuget -Name <Name of module>
```

Get the current module version  

```posh
    dotnet-gitversion|convertfrom-json
```

## Create new scaffold

Make a directory in the source code folder where the new module should be created.  

Create new module structure:  

```posh
dotnet new PSModuleBuilder -h
```

common parameters used when building a new module

```posh
dotnet new PSModuleBuilder -au "David Smith" -c "Wellspan Health" -de "Description"
dotnet new PSModuleBuilder -au "David Smith" -c "Wellspan Health" -de "SCOM Module built for Wellspan" -n "Wellspan.SCOM"
```

## Publish the module

Run the build command before publishing

```posh
Build-Module .\Source -SemVer 1.1.8
```

A basic publish command

```posh
Publish-module -Name .\output\dps\1.1.8 -Repository WellspanNuget  -NuGetApiKey 65bdeb92-10fa-476b-8064-e5f604467ba3 -Verbose
```

A more robust publish command using parameters

```posh
$parameters = @{
    Path        = '.\output\testmodule\1.1.7'
    NuGetApiKey = '65bdeb92-10fa-476b-8064-e5f604467ba3'
    Tag         = 'Test module','DPS'
    ReleaseNote = 'First test module built with Build-Module using scaffolding.'
}
Publish-Module @parameters -Verbose
```

Publish-Module Syntax

```text
Publish-Module -Name <string> [-RequiredVersion <string>] [-NuGetApiKey <string>] [-Repository <string>]
    [-Credential <pscredential>] [-FormatVersion {2.0}] [-ReleaseNotes <string[]>] [-Tags <string[]>]
    [-LicenseUri <uri>] [-IconUri <uri>] [-ProjectUri <uri>] [-Exclude <string[]>] [-Force]
    [-AllowPrerelease] [-SkipAutomaticTags] [-WhatIf] [-Confirm] [<CommonParameters>]

    Publish-Module -Path <string> [-NuGetApiKey <string>] [-Repository <string>]
    [-Credential <pscredential>] [-FormatVersion {2.0}] [-ReleaseNotes <string[]>]  
    [-Tags <string[]>] [-LicenseUri <uri>] [-IconUri <uri>] [-ProjectUri <uri>] [-Force] 
    [-SkipAutomaticTags] [-WhatIf] [-Confirm] [<CommonParameters>]
````

## Remove module from repository

This is a simple process.  The module needs to be deleted from the Nuget server.  This server is currently tsmgr4.  The module location is E:\Nuget.Server\Packages.  Delete the module from this folder
