#requires -version 4.0
<#
    .SYNOPSIS
        D3ploy aka Deploy v3: Powershell GUI (WPF + runspaces) to execute remote commands against a list of computers
		Mikel V. 2018/10/01

    .DESCRIPTION
        This script draws a WPF Form so you can easily choose a script from 'ScriptRepository' folder,
		write a list of target computers and choose the credentials needed to execute it.
		When creating your own scripts keep in mind that you can create levels in TreeView using underscore character "_" in script name.
		You can create:
			.bat files that will be executed against windows computers with psexec
			.ps1 regular scripts
			.txt files that will be executed against linux computers with plink

    .INPUTS
	The scripts in 'ScriptsRepository' Folder receive these 3 variables
        $computername:	The GUI exposes this variable with each computername in the computers textbox
		$scope:			The GUI exposes this variable with the description of credentials combobox
		$creds:			The GUI exposes this variable with PScredential Object of credentials combobox
		$credsplain:	The GUI exposes this variable with a pscustomobject with plain credentials ($credsplain.username and $credsplain.password)

    .OUTPUTS
        Outputs can be redirected to textblock in the GUI with out-textblock function.

    .EXAMPLE
		Create a ps1 script inside the 'ScriptRepository' Folder with this one-liner and name it Power Options_Restart Computer.ps1

		restart-computer -computername $computername -credential $creds -force

    .LINK
        http://sistemaswin.com

    .NOTES
        1. Choose the script you want to run from ScriptRepository
		2. Write the computernames in Computers textbox or select txt file that contains them
		3. If needed, Select proper credentials from the credentials combobox or write a description for new ones.
		4. Choose between the Pre-Deploy Options, whether you want to ping computers first, test the ports needed to work or do nothing
			*Debbuging checkbox will activate verbose and disable runspaces so you can see errors in console
		5. Run!

#>
. "$Psscriptroot\Functions\DeployFunctions.ps1"
##main##
import-module "$PSScriptRoot\..\_Modules\MiCredentialModule"
'Logs', 'Results', 'ScriptRepository'| % {if (!(test-path "$PSScriptRoot\$_")) {md "$PSScriptRoot\$_"|out-null}}

$uiHash = [hashtable]::Synchronized(@{})
$runspaceHash = [hashtable]::Synchronized(@{})
$jobs = [system.collections.arraylist]::Synchronized((New-Object System.Collections.Arraylist))
$uiHash.jobFlag = $True
$newRunspace = [runspacefactory]::CreateRunspace()
$newRunspace.ApartmentState = "STA"
$newRunspace.ThreadOptions = "ReuseThread"
$newRunspace.Open()
$newRunspace.SessionStateProxy.SetVariable("uiHash", $uiHash)
$newRunspace.SessionStateProxy.SetVariable("runspaceHash", $runspaceHash)
$newRunspace.SessionStateProxy.SetVariable("jobs", $jobs)
$uiHash.Psscriptroot = $Psscriptroot
$uihash.PreDeployOptions = 1

$identity = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).identities.name
Add-Type –assemblyName PresentationFramework
Add-Type –assemblyName PresentationCore
Add-Type –assemblyName WindowsBase
#Build the GUI
[xml]$xaml = @"
<Window Background="DarkGray"
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
Title="SistemasWin | MiShell Deploy | $identity" Height="550" Width="1100">
	<Grid x:Name="Grid" Margin="0" ShowGridLines="False" >
		<Grid.ColumnDefinitions>
			<ColumnDefinition Width="2*"/>
			<ColumnDefinition Width="*"/>
			<ColumnDefinition Width="4*"/>
		</Grid.ColumnDefinitions>
		<Grid x:Name="Grid1" Margin="0" ShowGridLines="False" Grid.Column="0" >
		<Grid.RowDefinitions>
			<RowDefinition Height="127"/>
			<RowDefinition Height="*"/>
		</Grid.RowDefinitions>
			<Image Source="$($uihash.Psscriptroot)\img\d3ploy_rocket.png" RenderOptions.BitmapScalingMode="HighQuality" HorizontalAlignment="Left" VerticalAlignment="Top" Grid.Row="0" />
		<TreeView x:Name = "TreeViewscripts" Background="Transparent" BorderBrush="Transparent" ScrollViewer.HorizontalScrollBarVisibility="Auto"  ScrollViewer.VerticalScrollBarVisibility="Auto" Grid.Row="1" Margin="0,0,0,10"/>

		</Grid>
		<Grid x:Name="Grid2" Margin="0" ShowGridLines="False" Grid.Column="1">
		<Grid.RowDefinitions>
			<RowDefinition Height="Auto"/>
			<RowDefinition Height="*"/>
			<RowDefinition Height="Auto"/>
		</Grid.RowDefinitions>
		<Expander Header="Explorer Buttons" Margin="2,2,2,1" BorderBrush="Gray" Grid.Row="0">
		<StackPanel Margin="2,4,2,0">
			<Button x:Name = "ButtonScriptRepository" Content="ScriptRepository"/>
			<Button x:Name = "ButtonLogs" Content="Logs"/>
			<Button x:Name = "ButtonResults" Content="Results"/>
			<Button x:Name = "ButtonComputers" Content="Add Computers List"/>
			</StackPanel>
			</Expander>
			<TextBox x:Name = "TextBoxComputers" TextWrapping="Wrap" AcceptsReturn="True" BorderBrush="Gray" ScrollViewer.HorizontalScrollBarVisibility="Disabled"  ScrollViewer.VerticalScrollBarVisibility="Auto" Grid.Row="1" Margin="2,0,2,1"/>
			<StackPanel Grid.Row="3" Grid.Column="0">
			<Label Margin="2,1,2,1" Content="Credentials"/>
			<ComboBox x:Name ="ComboBoxCreds" IsEditable="True" Margin="2,0,2,2"/>
			<Expander Header="Pre-Deploy Options" Margin="2,2,2,1" BorderBrush="Gray">
			<StackPanel Margin="10,4,10,0">
			<RadioButton x:Name="RadioButton1" Content = 'test-connection' GroupName='PreDeployOptions' Margin="0,2,0,1" IsChecked="True"/>
			<RadioButton x:Name="RadioButton2" Content = 'test-ports' GroupName='PreDeployOptions'/>
			<RadioButton x:Name="RadioButton3" Content = 'test-nothing' GroupName='PreDeployOptions' Margin="0,1,0,4"/>
			<Separator Width="Auto" HorizontalAlignment="Stretch" VerticalAlignment="Bottom" Background="Gray" />
			<CheckBox x:Name="CheckBoxRunspaces" Content="Debugging" ToolTip="Verbose=ON, Runspaces=OFF" Margin="0,2,0,4"/>
			</StackPanel>
			</Expander>
			<Button x:Name = "ButtonRun" Content="Run" Margin="2,2,2,10"/>
			</StackPanel>
		</Grid>
		<Grid x:Name="Grid3" Margin="0" ShowGridLines="False" Grid.Column="2">
		<Grid.RowDefinitions>
			<RowDefinition Height="*"/>
			<RowDefinition Height="10"/>
		</Grid.RowDefinitions>
			<ScrollViewer x:Name = "scrollviewer" VerticalScrollBarVisibility="Visible">
				<TextBlock x:Name = "textblock" Background="#272822" Foreground="white" FontFamily="Lucida Console" TextWrapping = "Wrap" Grid.Row="0"  Padding="4"/>
			</ScrollViewer>
			<ProgressBar x:Name="ProgressBar" Minimum="0" Maximum="100" Grid.Row="1" />
		</Grid>

	</Grid>
</Window>
"@
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$uiHash.Window = [Windows.Markup.XamlReader]::Load( $reader )

#Connect to Controls (Boe Prox's spell)
$xaml.selectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")| % {
	$uiHash.Add($_.name, $uiHash.Window.FindName($_.Name))
}
$null = fill-treeview "$($uihash.Psscriptroot)\ScriptRepository\*" $uihash.TreeViewscripts
if (test-path "$($uihash.PSScriptroot)\creds") {$array = gci ("$($uihash.PSScriptroot)\creds\$($env:username)" + "_*.cred")|select @{l = 'basename'; e = {$_.basename -replace ("$($env:username)_")}}|select -expand basename
}
if ($array -eq $null) {$array = ""}

if ($array.gettype().name -eq "Object[]") {
	$uihash.ComboBoxcreds.text = $array[0]
	$array| % {$uihash.ComboBoxcreds.addChild($_)}
}
else {$uihash.ComboBoxcreds.text = $array}

$uihash.TreeViewscripts.items.Add_Selected( {
		if ([bool]$_.OriginalSource.tag) {
			$uihash.Tag = $_.OriginalSource.tag
			$uihash.fullscriptname = '{0}\ScriptRepository\{1}' -f $uihash.PSScriptroot, $_.OriginalSource.tag
		}
		else {$uihash.fullscriptname = $uihash.Tag = $null}

	})
#Jobs runspace
$runspace = [runspacefactory]::CreateRunspace()
$runspace.Open()
$runspace.SessionStateProxy.SetVariable("uihash", $uihash)
$runspace.SessionStateProxy.SetVariable("jobs", $jobs)
$runspaceHash.PowerShell = [powershell]::Create().AddScript( {
		While ($uihash.jobFlag) {
			If ($jobs.Handle.IsCompleted) {
				$jobs.PowerShell.EndInvoke($jobs.handle)
				$jobs.PowerShell.Dispose()
				$jobs.clear()
			}
		}
	})
$runspaceHash.PowerShell.Runspace = $runspace
$runspaceHash.Handle = $runspaceHash.PowerShell.BeginInvoke()
$uiHash.flag = $False

#Events
$uiHash.Window.Add_Closed( {
		$uiHash.jobFlag = $False
		sleep -Milliseconds 500
		$runspaceHash.PowerShell.EndInvoke($runspaceHash.Handle)
		$runspaceHash.PowerShell.Dispose()
		$runspaceHash.Clear()
	})
$uihash.ButtonScriptRepository.Add_Click( {
		Invoke-Item "$PSScriptRoot\ScriptRepository"
	})
$uihash.ButtonResults.Add_Click( {
		Invoke-Item "$PSScriptRoot\Results"
	})
$uihash.ButtonLogs.Add_Click( {
		Invoke-Item "$PSScriptRoot\Logs"
	})
$uihash.ButtonComputers.Add_Click( {
		$OpenFileDialog = New-Object Microsoft.Win32.OpenFileDialog
		$OpenFileDialog.initialDirectory = $uihash.PSScriptroot
		$OpenFileDialog.filter = "txt (*.txt)| *.txt"
		$OpenFileDialog.ShowDialog() | Out-Null
		if ($OpenFileDialog.FileName) {
			$uiHash.TextBoxComputers.Dispatcher.Invoke([action] {
					$uiHash.TextBoxComputers.AppendText((get-content $OpenFileDialog.filename) -join "`r")

				}, "Normal")

		}
	})
$uiHash.ButtonRun.Add_Click( {
		if ([bool]$uihash.TextBoxComputers.text -and [bool]$uihash.fullscriptname) {

			$uihash.extension = $uihash.tag.split("\.")[1]
			switch ($uihash.extension) {
				"bat" {
					$uihash.defaultlogfile = 'psexec.log'; $uiHash.ports = 139, 445
				}
				"ps1" {
					$uihash.defaultlogfile = 'ps1command.log'; $uiHash.ports = 139, 445, 5985
				}
				"txt" {
					$uihash.defaultlogfile = 'plink.log'; $uiHash.ports = 22
				}
			}

			Switch ($uiHash.Flag) {
				$True {
					#Stop!!!
					$uiHash.Flag = $False
					$uiHash.buttonRun.Content = 'Run'
					out-textblock -message "DEPLOY CANCELLED" -MessageType "Error" -logfile $uihash.defaultlogfile
				}
				$False {
					$uiHash.Flag = $True
					$uiHash.buttonRun.Content = 'Stop'
					$uihash.scope = $uihash.ComboBoxcreds.text
					if ($uihash.scope -ne '') {
						$uihash.creds = select-MiCredential -scope $uihash.scope
						$uihash.credsplain = select-MiCredential -scope $uihash.scope -plain
						out-textblock -Source "Credentials" -Message "Using $($uihash.scope) ($($uihash.creds.username))" -MessageType 'Info' -logfile $uihash.defaultlogfile
					}
					else {out-textblock -Source "Credentials" -Message "Using Current Credentials ($identity)" -MessageType 'Info' -logfile $uihash.defaultlogfile}
					$uihash.objcomputers = new-object system.collections.stack
					($uihash.TextBoxComputers.text -split ("`r")) -replace "`#.*", "$([char]0)" -replace "#.*" -replace "$([char]0)", "#" -replace "^\s*" -replace "\s*$"|? {$_}| % {
						$uihash.objcomputers.Push($_)}
					$scriptBlock = {
						. "$($uihash.Psscriptroot)\Functions\DeployFunctions.ps1"
						$scope = $uihash.scope
						$creds = $uihash.creds
						$credsplain = $uihash.credsplain
						$ProgressBarTotal = $uihash.objcomputers.count
						$ProgressBarCount = 0
						out-textblock -message "Deploying $($uihash.tag)" -MessageType "Info"
						do {
							if (-NOT $uiHash.Flag) {break}
							$ProgressBarCount++
							$ProgressBarPercent = [int](($ProgressBarCount / $ProgressBartotal) * 100)
							update-window -control "ProgressBar" -property "Value" -Value $ProgressBarPercent
							$computername = $uihash.objcomputers.pop()
							switch ($uihash.PreDeployOptions) {
								1 {$computername = ping-computer $computername}
								2 {$computername = test-ports $computername ($uiHash.ports)}
							}
							if ([bool]$computername) {
								switch ($uihash.extension) {
									"bat" {
										$cmdkeyadd = "cmdkey.exe /add:" + $computername + " /user:" + $credsplain.username + " /pass:'" + $credsplain.password + "'"
										if ($scope -ne '') {$psexeccommand = "{0}\..\_bin\psexec.exe \\{1} -accepteula -v -n 10 -u {2} -p '{3}' -h -d -c '{4}'" -f $uihash.psscriptroot, $computername, $credsplain.username, $credsplain.password, $uihash.fullscriptname}
										else {$psexeccommand = "{0}\..\_bin\psexec.exe \\{1} -accepteula -v -n 10 -h -d -c '{2}'" -f $uihash.psscriptroot, $computernames, $uihash.fullscriptname}
										$cmdkeydelete = "cmdkey.exe /delete:" + $computername
										if ($scope -ne '') {invoke-expression $cmdkeyadd}
										invoke-expression $psexeccommand
										$msg = "{0}: Executing: {1} exitcode:{2}" -f $computername, $uihash.tag, $lastexitcode
										if ($lastexitcode -in (5, 6, 50, 53, 122, 1311, 1326, 1385, 1460, 2250)) {$type = 'Error'}else {$type = 'OK'}
										out-textblock -ComputerName $computername -Source "Psexec" -Message $msg -MessageType $Type -logfile 'psexec.log'
										if ($scope -ne '') {invoke-expression $cmdkeydelete}
									}
									"ps1" {. $uihash.fullscriptname}
									"txt" {
										$plinkcommand = "{0}\..\_bin\plink.exe -v {2}@{1} -pw '{3}' -m '{4}' >> 'Results\{5}.txt'" -f $uihash.psscriptroot, $computername, $credsplain.username, $credsplain.password, $uihash.fullscriptname, $uihash.tag
										invoke-expression $plinkcommand
										$msg = "{0}: exitcode:{1} executing:{2}" -f $computername, $lastexitcode, $uihash.tag
										if ($lastexitcode -eq 1) {$type = 'Error'}else {$type = 'OK'}
										out-textblock -ComputerName $computername -Source "Plink" -Message $msg -MessageType $type -logfile 'plink.log'
									}
								}


							}
						}while ($uiHash.Flag -and $uihash.objcomputers.count -gt 0)
						out-textblock -message "END OF DEPLOYMENT" -MessageType "Info"
						$uiHash.Flag = $False
						update-window -control 'ButtonRun' -property 'Content' -value 'Run'
					}#scriptblock
					if ($uihash.CheckBoxRunspaces.isChecked) {
						$currentVerbosePreference = $VerbosePreference
						$VerbosePreference = "Continue"
						invoke-command -ScriptBlock $scriptBlock -NoNewScope
						$VerbosePreference = $currentVerbosePreference
					}
					else {
						$runspace = [runspacefactory]::CreateRunspace()
						$runspace.Open()
						$runspace.SessionStateProxy.SetVariable("uiHash", $uiHash)
						$temp = "" | Select PowerShell, Handle
						$temp.PowerShell = [powershell]::Create().AddScript($scriptBlock)
						$temp.PowerShell.Runspace = $runspace
						$temp.Handle = $temp.PowerShell.BeginInvoke()
						$jobs.Add($temp)
					}

				}
			}#switch

		}
		else {out-textblock -message "NOTHING TO DEPLOY" -MessageType "Warning"}
	})

$uihash.RadioButton1.Add_Checked( {
		$uihash.PreDeployOptions = 1
	})
$uihash.RadioButton2.Add_Checked( {
		$uihash.PreDeployOptions = 2
	})
$uihash.RadioButton3.Add_Checked( {
		$uihash.PreDeployOptions = 3
	})
$host.ui.RawUI.WindowTitle = "SistemasWin | MiShell Deploy | $identity"
write-host ''
write-host '  8888888P.                    888'                       -fore Gray
write-host '  888  "788b                   888'                       -fore Gray
write-host '  888    888                   888'                       -fore Gray
write-host '  888    888 ,A8888A, 88888Y,  888 ,A8888A, 888  888'     -fore Gray
write-host '  888    888 888  888 888 "88Y 888 888  888 888  888'     -fore Gray
write-host '  888    888 888888Y" 888  888 888 888  888 888  888'     -fore DarkGray
write-host '  888  ,d88P 888      888  888 888 888  888 Y88b 888'     -fore DarkGray
write-host '  8888888K"  "Y8888Y" 888888Y" 888 "Y8888Y"  "Y88888'     -fore DarkGray
write-host '                      888                       "888'     -fore DarkGray
write-host '                      888                       .888'     -fore DarkGray
write-host '                      888                    8888P" '     -fore DarkGray
write-host ''
$uiHash.Window.ShowDialog() | Out-Null