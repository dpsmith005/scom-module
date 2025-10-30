<#
.SYNOPSIS
	Read CSV to display input window
.DESCRIPTION
	This script will read an input file, display the variables entered, and save user input.  
	The csvFile contains the field label, the field type, and the input width
	The type can be string for string values, int for integer values, dec for decimals.
.PARAMETER csvInputFile
	The file name of the CSV to build the GUI.  This GUI will allow user input
.PARAMETER csvOutputFile
	The file name of the CSV where the data will be saved
.PARAMETER Height
	Value for the form Width
.PARAMETER Width
	Value for the form Height
.EXAMPLE
	PoshGuiInput.ps1 c:\path\InputFile.csv

	This will read the specified input CSV file to display a GUI for daa entry
.NOTES
	Version:        1.0
	Author:         David Smith
	Creation Date:  29 October 2025
	Updated Date:   30 October 2025 by David Smith
	Purpose/Change: Initial script development for shared scripts
#>
[CmdletBinding()]
Param([Parameter(Mandatory = $true, Position = 0)][string]$csvInputFile,
	  [Parameter(Mandatory = $true, Position = 1)][string]$csvOutputFile,
	  [Parameter(Mandatory = $true, Position = 2)][int]$Height,
	  [Parameter(Mandatory = $true, Position = 3)][int]$Width
)

$DEBUG = $false
If ($PSBoundParameters.ContainsKey('Debug')) {
	$DebugPreference = 'Continue'
	$DEBUG = $true
}

Write-Debug "Checking to see if the input file exists ($csvInputFile)..."
if (Test-Path -Path $csvInputFile) {
	$data = Import-CSV $csvInputFile
} else {
	Write-Error "The file $csvInputFile was not found"
	return 1
}
Write-Debug "CSV file exists.  Verifying the input..."

$arrVariables = @()
foreach ($line in $data) {
	if ($line.Type -eq "string" -or $line.Type -eq "int" -or $line.Type -eq "dec" -or $line.Type -eq "checkbox" -or $line.Type -eq "combobox") {
		Write-Debug "$($line.Label) is type $($line.Type) width $($line.Width)"
		$arrVariables += [PSCustomObject]@{
			Label 	  = $line.Label
			Type      = $line.Type
			Width	  = $line.Width
			Items 	  = $line.Items
			varLabel  = "label_" + ($line.Label -replace " ","_")
			varInput  = "$($line.Type)_" + ($line.Label -replace " ","_") 
		}
	} else {
		Write-Error -Message "Lablel $($line.Label) incorect type $($line.Type)" -ErrorId TypeNotFound -Category ObjectNotFound
		return 2
	}
}
Write-Debug "Input CSV data is correct"

#region Import the Assemblies
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
#endregion

#region Generated Form Objects
$form1 = New-Object System.Windows.Forms.Form
Write-Debug "Create the form objects"
foreach ($line in $arrVariables) {
	Switch ($line.Type) {
		"string" {
			Set-Variable -Name $($line.varLabel) -Value (New-Object System.Windows.Forms.Label)
			Set-Variable -Name $($line.varInput) -Value (New-Object System.Windows.Forms.TextBox)
		}
		"int" {
			Set-Variable -Name $($line.varLabel) -Value (New-Object System.Windows.Forms.Label)
			Set-Variable -Name $($line.varInput) -Value (New-Object System.Windows.Forms.TextBox)
		}
		"dec" {
			Set-Variable -Name $($line.varLabel) -Value (New-Object System.Windows.Forms.Label)
			Set-Variable -Name $($line.varInput) -Value (New-Object System.Windows.Forms.TextBox)
		}
		"checkbox" {
			Set-Variable -Name $($line.varLabel) -Value (New-Object System.Windows.Forms.Label)
			Set-Variable -Name $($line.varInput) -Value (New-Object System.Windows.Forms.CheckBox)
		}
		"combobox" {
			Set-Variable -Name $($line.varLabel) -Value (New-Object System.Windows.Forms.Label)
			Set-Variable -Name $($line.varInput) -Value (New-Object System.Windows.Forms.ComboBox)
		}
		default {Write-Error -Message "Incorect lable type Lable: $($line.Label)  Type: $($line.Type)" -ErrorId TypeNotFound -Category ObjectNotFound}
	}
}
$buttonSave = New-Object System.Windows.Forms.Button	#Save Button
$buttonExit = New-Object System.Windows.Forms.Button	#Exit Button
	
Write-Debug "Variables Created"
if ($DEBUG) {Get-Variable label*, string*, int*, dec*, checkbox*, comboBox*}

$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
#endregion Generated Form Objects

#----------------------------------------------
#Generated Event Script Blocks
#----------------------------------------------
$buttonSave_OnClick= 
{
	# Add the code to save the form data to a text file
	Write-Debug "Saving form data to file"
	$dataToSave = [PSCustomObject]@{}
	foreach ($line in $arrVariables) {
		$label = $line.Label -replace " ","_"
		switch ($line.Type) {
			"string" {
				$textbox = (Get-Variable $line.varInput).Value
				$dataToSave | Add-Member  -MemberType NoteProperty -Name $label -Value ([string]$($textBox.Text))
				Write-Debug "$label $($textBox.Text)"
			}
			"int" {
				$textbox = (Get-Variable $line.varInput).Value
				$dataToSave | Add-Member  -MemberType NoteProperty -Name $label -Value ([int]$($textBox.Text))
				Write-Debug "$label $($textBox.Text)"
			}
			"dec" {
				$textbox = (Get-Variable $line.varInput).Value
				$dataToSave | Add-Member  -MemberType NoteProperty -Name $label -Value ([decimal]$($textBox.Text))
				Write-Debug "$label $($textBox.Text)"
			}
			"comboBox" {
				$combobox = (Get-Variable $line.varInput).Value
				$dataToSave | Add-Member  -MemberType NoteProperty -Name $label -Value $comboBox.SelectedItem
				Write-Debug "$label $($COMBObOX.Text)"
			}
			"checkbox" {
				$checkBox = (Get-Variable $line.varInput).Value
				$dataToSave | Add-Member -MemberType NoteProperty -Name $label -Value $checkBox.Checked
				Write-Debug "$label $($checkBox.Checked)"
			}
		}
	}
	$dataToSave
	# VALIDATE the data. int is an integer.  dec is a decimal
	$dataToSave | Export-Csv -Path $csvOutputFile -Append -NoTypeInformation
	
	# Add code to clear input fields
<#
	foreach ($line in $arrVariables) {
		if ($line.Type -eq "string" -or $line.Type -eq "int" -or $line.Type -eq "dec") {
			$textbox = (Get-Variable $line.varInput).Value
			$textBox.Text = ""
		} elseif ( $line.Type -eq "checkbox") {
			$checkBox = (Get-Variable $line.varInput).Value
			$checkBox.Checked = $false
		}
	}
#>
	# Refresh the data grid view
	$dataTable = New-Object System.Data.DataTable
	$csvData = Import-Csv -Path $csvOutputFile
	# Assuming all columns are strings for simplicity. Adjust data types as needed.
	foreach ($property in $csvData[0].PSObject.Properties) {
		$column = New-Object System.Data.DataColumn ($property.Name, [string])
		$dataTable.Columns.Add($column)
	}
	# Add data to the datGridView
	foreach ($rowObject in $csvData) {
		$newRow = $dataTable.NewRow()
		foreach ($property in $rowObject.PSObject.Properties) {
			$newRow.$($property.Name) = $property.Value
		}
		$dataTable.Rows.Add($newRow)
	}
	$dataGridView1.DataSource = $null
	$dataGridView1.DataSource = $dataTable
	$dataGridView1.Refresh()
}
#-----------------------------------------------

$OnLoadForm_StateCorrection=
{#Correct the initial state of the form to prevent the .Net maximized form issue
	$form1.WindowState = $InitialFormWindowState
}

#region Generated Form Code
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = $Height
$System_Drawing_Size.Width = $Width
$form1.ClientSize = $System_Drawing_Size
$form1.DataBindings.DefaultDataSourceUpdateMode = 0
$form1.Name = "form1"
$form1.StartPosition = 0
#$System_Drawing_Point = New-Object System.Drawing.Point	# Location
#$System_Drawing_Point.X = 1610
#$System_Drawing_Point.Y = 820
#$form1.Location = $System_Drawing_Point
$form1.Text = "User Input Form"

# Add all the labels and inputs
$Y = 5
$tabIndex = 0
foreach ($line in $arrVariables) {
	$label = (Get-Variable $line.varLabel).Value
	switch ($line.Type) {
		{ $_ -in "string", "int", "dec" }  {
			$label.DataBindings.DefaultDataSourceUpdateMode = 0
			$System_Drawing_Point = New-Object System.Drawing.Point
			$System_Drawing_Point.X = 5
			$System_Drawing_Point.Y = $Y
			$label.Location = $System_Drawing_Point
			$label.Name = $line.varLabel
			$System_Drawing_Size = New-Object System.Drawing.Size
			$System_Drawing_Size.Height = 20
			$System_Drawing_Size.Width = 150
			$label.Size = $System_Drawing_Size
			$label.TabIndex = $tabIndex
			$label.Text = $line.Label
			$label.TextAlign = 64
			$form1.Controls.Add($label)
			
			$textbox = (Get-Variable $line.varInput).Value
			$tabIndex++
			$textBox.DataBindings.DefaultDataSourceUpdateMode = 0
			$System_Drawing_Point = New-Object System.Drawing.Point
			$System_Drawing_Point.X = 161
			$System_Drawing_Point.Y = $Y
			$textBox.Location = $System_Drawing_Point
			$textBox.Name = $line.varLabel
			$System_Drawing_Size = New-Object System.Drawing.Size
			$System_Drawing_Size.Height = 20
			$System_Drawing_Size.Width = $line.Width
			$textBox.Size = $System_Drawing_Size
			$textBox.TabIndex = $tabIndex
			
			if ($line.Type -eq "int") {
				$textBox.Text = "0"
				# Define the Validating event handler for integers
				$textBox.Add_Validating({
					param($sender, $e)

					$outputInt = 0

					if (-not [int]::TryParse($sender.Text, [ref]$null)) {
						$status.Text = "Please enter a valid integer."
						$e.Cancel = $true # Prevent focus from leaving the textbox
					# Allow empty
					#} elseif ([string]::IsNullOrEmpty($sender.Text)) {
					#	$status.Text = "Input cannot be empty."
					#	$e.Cancel = $true # Prevent focus from leaving the textbox
					} else {
						$status.Text = "" # Clear error message if validation passes
						$e.Cancel = $false
					}
				})
			}
			if ($line.Type -eq "dec") {
				$textBox.Text = "0"
				# Define the validating for decimals	
				$textBox.Add_Validating({
					param($sender, $e)

					if (-not [decimal]::TryParse($sender.Text, [ref]$null)) {
						$e.Cancel = $true # Prevent focus from leaving the textbox
						$status.Text = "Invalid decimal value."
					} else {
						$status.Text = "" # Clear error message
					}
				})
			}
			
			$form1.Controls.Add($textBox)
		}
		"combobox" {	
			$label.DataBindings.DefaultDataSourceUpdateMode = 0
			$System_Drawing_Point = New-Object System.Drawing.Point
			$System_Drawing_Point.X = 5
			$System_Drawing_Point.Y = $Y
			$label.Location = $System_Drawing_Point
			$label.Name = $line.varLabel
			$System_Drawing_Size = New-Object System.Drawing.Size
			$System_Drawing_Size.Height = 20
			$System_Drawing_Size.Width = 150
			$label.Size = $System_Drawing_Size
			$label.TabIndex = $tabIndex
			$label.Text = $line.Label
			$label.TextAlign = 64
			$form1.Controls.Add($label)

			$comboBox = (Get-Variable $line.varInput).Value
			$tabIndex++
			$comboBox.DataBindings.DefaultDataSourceUpdateMode = 0
			$comboBox.FormattingEnabled = $True
			foreach ($item in ($line.items.Split(":"))) {
				$comboBox.Items.Add("$item")|Out-Null
			}
			$System_Drawing_Point = New-Object System.Drawing.Point
			$System_Drawing_Point.X = 161
			$System_Drawing_Point.Y = $Y
			$comboBox.Location = $System_Drawing_Point
			$comboBox.Name = $line.varLabel
			$System_Drawing_Size = New-Object System.Drawing.Size
			$System_Drawing_Size.Height = 20
			$System_Drawing_Size.Width = $line.Width
			$comboBox.Size = $System_Drawing_Size
			$comboBox.TabIndex = $tabIndex
		
			$form1.Controls.Add($comboBox)
		}
		"checkbox" {
			$checkBox = (Get-Variable $line.varInput).Value
			
			$checkBox.DataBindings.DefaultDataSourceUpdateMode = 0
			$System_Drawing_Point = New-Object System.Drawing.Point
			$System_Drawing_Point.X = 161
			$System_Drawing_Point.Y = $Y
			$checkBox.Location = $System_Drawing_Point
			$checkBox.Name = $line.varLabel
			$System_Drawing_Size = New-Object System.Drawing.Size
			$System_Drawing_Size.Height = 20
			$System_Drawing_Size.Width = 150
			$checkBox.Size = $System_Drawing_Size
			$checkBox.TabIndex = $tabIndex
			$checkBox.Text = $line.Label
			$checkBox.UseVisualStyleBackColor = $True

			$form1.Controls.Add($checkBox)
		}
	}
	$Y += 20
	$tabIndex++
}
#endregion Generated Form Code

# Save button to save data to a file
$buttonSave.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 75
$System_Drawing_Point.Y = $Y
$buttonSave.Location = $System_Drawing_Point
$buttonSave.Name = "buttonSave"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 75
$buttonSave.Size = $System_Drawing_Size
$buttonSave.TabIndex = $tabIndex
$buttonSave.Text = "Save"
$buttonSave.UseVisualStyleBackColor = $True
$buttonSave.add_Click($buttonSave_OnClick)
$form1.Controls.Add($buttonSave)
$tabIndex++

# Save button to save data to a file
$buttonExit.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 160
$System_Drawing_Point.Y = $Y
$buttonExit.Location = $System_Drawing_Point
$buttonExit.Name = "buttonExit"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 75
$buttonExit.Size = $System_Drawing_Size
$buttonExit.TabIndex = $tabIndex
$buttonExit.Text = "Exit"
$buttonExit.UseVisualStyleBackColor = $True
$buttonExit.add_Click({ $form1.Close() })
$form1.Controls.Add($buttonExit)
$tabIndex++
$Y += 20

$Status = New-Object System.Windows.Forms.Label
$Status.DataBindings.DefaultDataSourceUpdateMode = 0
$Status.Dock = 2
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 0
$System_Drawing_Point.Y = 321
$Status.Location = $System_Drawing_Point
$Status.Name = "Status"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 20
$System_Drawing_Size.Width = 586
$Status.Size = $System_Drawing_Size
$Status.TabIndex = 3
$Status.Text ="Status bar"
$Status.TextAlign = 16

$form1.Controls.Add($Status)
$dataGridView1 = New-Object System.Windows.Forms.DataGridView
$dataGridView1.DataBindings.DefaultDataSourceUpdateMode = 0
#$dataGridView1.Dock = 2
$dataGridView1.AllowUserToAddRows = $False
$dataGridView1.AllowUserToDeleteRows = $False
$dataGridView1.Anchor = 15
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 0
$System_Drawing_Point.Y = ($Y + 10)
$dataGridView1.Location = $System_Drawing_Point
$dataGridView1.Name = "dataGridView1"
$dataGridView1.ReadOnly = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = ($Height - $Y - 20)
$System_Drawing_Size.Width = ($Width - 20)
$dataGridView1.Size = $System_Drawing_Size
$dataGridView1.TabIndex = $tabIndex
 # Populate the data grid view
 $dataTable = New-Object System.Data.DataTable
 if (Test-Path $csvOutputFile) {
	 $csvData = Import-Csv -Path $csvOutputFile
	 # Assuming all columns are strings for simplicity. Adjust data types as needed.
	 foreach ($property in $csvData[0].PSObject.Properties) {
		$column = New-Object System.Data.DataColumn ($property.Name, [string])
		$dataTable.Columns.Add($column)
	 }
	 # Add data to the datGridView
	 foreach ($rowObject in $csvData) {
		$newRow = $dataTable.NewRow()
		foreach ($property in $rowObject.PSObject.Properties) {
			$newRow.$($property.Name) = $property.Value
		}
		$dataTable.Rows.Add($newRow)
	}
	$dataGridView1.DataSource = $dataTable
 }
$form1.Controls.Add($dataGridView1)

#Save the initial state of the form
$InitialFormWindowState = $form1.WindowState
#Init the OnLoad event to correct the initial state of the form
$form1.add_Load($OnLoadForm_StateCorrection)
#Show the Form
$form1.ShowDialog()| Out-Null

Write-Host "The variable dataToSave contains the contents last saved on the screen"
$dataToSave