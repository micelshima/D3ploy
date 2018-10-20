<#
.Synopsis
   Store PSCredential to file for later use (DPAPI encryption).
.DESCRIPTION
   Saves/Retrieves credentials to/from a file (with encrypted password) so you can automate tasks that need different credentials
.PARAMETER scope
   Scope of the credential. If omitted a form will show up to select saved credential or create new one
.PARAMETER plain
   Retrieves credentials with plain username and password in case you need to use them in  external commands. p.e psexec.

.EXAMPLE
   Select-MiCredential -scope "myDomain"
   This command will return a PSCredential Object with credentials previously stored for "myDomain".
   If file doesn't exist yet, it will ask for credentials and save the file on the fly.
.EXAMPLE
   Select-MiCredential -scope "myDomain" -plain
   This command will return an object with username and plain password with credentials previously stored for "myDomain".
   If file doesn't exist yet it will ask for credentials and save the file on the fly.
.EXAMPLE
   Select-MiCredential
   This command will show a form with a dropdown menu to choose proper credential from  stored files
   If dropdown menu is empty is because you didn't store any credential yet, then you can type the scope you want and then fill in your credentials.
.OUTPUTS
   PowerShell object with username and password.
.NOTES
   Author : Mikel V.
   version: 0.9
   Date   : 2017/02/25
.LINK
   https://sistemaswin.com
#>

Function select-MiCredential {
	[cmdletBinding()]
	param(
		[Parameter(ValueFromPipeline = $true)]
		[string]$scope,
		[Switch]$plain
	)
	process {
		if (!$scope) {$scope = credentialWinForm}
		$scope = $scope -replace ('[\\/:*?"<>|]', ' ')
		$credfile = "$pwd\creds\$($env:username)_$scope.cred"
		if (!(test-path -path $credfile)) {
			if (!(test-path -path "$pwd\creds")) {new-item -itemtype directory -path "$pwd\creds"|out-null}
			write-warning "$($env:username), you must provide credentials to manage $scope"
			$objcreds = get-credential
			$creds = ""|select username, Password
			$creds.username = $objcreds.username
			#DPAPI encryption
			#if ($PSVersionTable.PSVersion.Major -ge 5) {$creds.password = $objcreds.GetNetworkCredential().Password|convertfrom-securestring}
			#else {$creds.password = $objcreds.GetNetworkCredential().Password|ConvertTo-SecureString -AsPlainText -Force|convertfrom-securestring}
			$creds.password = $objcreds.GetNetworkCredential().Password|ConvertTo-SecureString -AsPlainText -Force|convertfrom-securestring
			Export-CliXML -path $credfile -input $creds
		}
		$storedcreds = Import-CliXML -path $credfile
		$password = ConvertTo-SecureString $storedcreds.password
		write-verbose "$($storedcreds.username) credentials will be used to manage $scope"
		if ($plain) {
			$creds = ""|select username, Password
			$creds.username = $storedcreds.username
			$helper = New-Object system.Management.Automation.PSCredential("anybody", $password)
			$creds.password = $helper.GetNetworkCredential().Password
		}
		else {
			$creds = New-Object System.Management.Automation.PSCredential($storedcreds.username, $password)
		}
		return $creds
	}
}

Function dropdownlist() {
	$username = $env:username
	if (test-path "$pwd\creds") {$array = get-childitem ("$pwd\creds\$username" + "_*.cred")|select @{l = 'basename'; e = {$_.basename -replace ("$($username)_")}}|select -expand basename
	}
	if ($array -eq $null) {$array = ""}
	return $array
}
Function credentialWinForm() {
	$array = dropdownlist
	[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
	$MyForm = New-Object System.Windows.Forms.Form
	$Icon = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")
	$MyForm.Icon = $Icon
	$MyForm.Size = New-Object System.Drawing.Size(250, 130)
	$MyForm.StartPosition = "CenterScreen"
	$MyForm.BackColor = [System.Drawing.Color]::Snow
	$Myform.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
	$Myform.topMost = $true
	$objLabel1 = New-Object System.Windows.Forms.Label
	$objLabel1.Location = New-Object System.Drawing.Point(5, 10)
	$objLabel1.Size = New-Object System.Drawing.Size(100, 20)
	$objLabel1.Text = "Select credentials"
	$MyForm.Controls.Add($objLabel1)
	$objComboBox1 = New-Object System.Windows.Forms.ComboBox
	$objComboBox1.Location = New-Object System.Drawing.Point(5, 30)
	$objComboBox1.Size = New-Object System.Drawing.Size(220, 20)
	$objComboBox1.Name = "creds"
	$objComboBox1.items.addrange($array)
	if ($array.gettype().name -eq "Object[]") {$objComboBox1.text = $array[0]}
	else {$objComboBox1.text = $array}
	$MyForm.Controls.Add($objComboBox1)
	$objComboBox1.Add_KeyDown( {
			if ($_.KeyCode -eq "Enter") {
				$script:scope = $objComboBox1.text
				$MyForm.hide()
				$MyForm.dispose()
			}
		})
	$buttonselect = New-Object Windows.Forms.Button
	$buttonselect.Location = New-Object System.Drawing.Point(5, 60)
	$buttonselect.Size = New-Object System.Drawing.Size(220, 20)
	$buttonselect.BackColor = [System.Drawing.Color]::WhiteSmoke
	$buttonselect.text = "Load!"
	$MyForm.Controls.Add($buttonselect)
	$buttonselect.Add_Click( {
			$script:scope = $objComboBox1.text
			$MyForm.hide()
			$MyForm.dispose()
		})
	# Activates/draws the form.
	$myForm.Add_Shown( {$myForm.Activate()})
	[void] $MyForm.ShowDialog()
	return $script:scope
}
#export-modulemember -function select-MiCredential