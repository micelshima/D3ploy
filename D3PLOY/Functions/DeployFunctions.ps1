Function fill-TreeView($scriptsrepository, $object) {
	$treeseparator = "_"
	$object.items.clear()
	foreach ($scriptname in (gci $scriptsrepository -include *.ps1, *.bat, *.txt|sort name|select -expand name)) {
		$parent = $object
		foreach ($item in $scriptname.split($treeseparator)) {
			$flag = $true
			$parent.items| % {if ($_.name -eq ($item -replace (" ", $treeseparator))) {$parent = $_; $flag = $false}}
			if ($flag) {
				$ChildItem = New-Object System.Windows.Controls.TreeViewItem
				$label = New-Object System.Windows.Controls.label
				$label.fontSize = "12"
				$img = New-Object System.Windows.Controls.Image
				$img.height = "12"
				$stack = New-Object System.Windows.Controls.StackPanel
				$stack.orientation = "Horizontal"
				if ($item -match "\.") {
					$extension = $item.split(".")[1]
					$item = $item.split(".")[0]
					$ChildItem.Tag = $scriptname
				}
				else {
					$extension = "folder"
					$ChildItem.Name = $item -replace (" ", $treeseparator)
				}
				$img.source = '{0}\img\{1}.png' -f $uihash.PSscriptroot, $extension
				$stack.children.add($img)
				$label.content = $item
				$stack.children.add($label)
				$ChildItem.Header = $stack
				#[Void]$ChildItem.Items.Add("subitem")
				[Void]$parent.Items.Add($ChildItem)
				$parent = $ChildItem
			}
		}
	}
}#end fill-treeview
Function out-textblock {
	PARAM(
		[Parameter(ValueFromPipeline = $True,
			ValueFromPipelineByPropertyName = $True)]
		[String[]]$Message,
		[string]$MessageType,
		[string]$DateTimeColor = '#f7f7f1',
		[string]$Source,
		[string]$SourceColor = '#f7f7f1',
		[string]$ComputerName,
		[String]$ComputerNameColor = '#fd971f',
		[String]$logfile)
	Begin {
		$Sortabledate = get-date -Format "yyyy/MM/dd HH:mm:ss"
		$SortableTime = get-date -Format "HH:mm:ss"

		$uihash.textblock.Dispatcher.Invoke([action] {
				$Run = New-Object System.Windows.Documents.Run
				$Run.Foreground = $DateTimeColor
				$Run.text = "$SortableTime "
				$uihash.textblock.Inlines.Add($Run)
			}, "Send")
		$uihash.textblock.Dispatcher.Invoke([action] {
				IF ($PSBoundParameters['ComputerName']) {
					$Run = New-Object System.Windows.Documents.Run
					$Run.Foreground = $ComputerNameColor
					$Run.text = ("$ComputerName ").ToUpper()
					$uihash.textblock.Inlines.Add($Run)
				}
			}, "Send")
		$uihash.textblock.Dispatcher.Invoke([action] {
				IF ($PSBoundParameters['Source']) {
					$Run = New-Object System.Windows.Documents.Run
					$Run.Foreground = $SourceColor
					$Run.text = "$Source "
					$uihash.textblock.Inlines.Add($Run)
				}
			}, "Send")
		switch ($MessageType) {
			"OK" {$MessageColor = '#a3de2d'}
			"ERROR" {$MessageColor = '#c3265d'}
			"warning" {$MessageColor = '#d5cb6d'}
			"Info" {$MessageColor = '#66d9ef'}
			default {$MessageColor = '#f7f7f1'}
		}
	}

	Process {
		ForEach ($Message1 in ($Message|? {[bool]$_})) {
			$uihash.textblock.Dispatcher.Invoke([action] {
					#$Message1 = $Message1.split(" ")
					$Run = New-Object System.Windows.Documents.Run
					$Run.Foreground = $MessageColor
					$Run.text = $Message1
					$uihash.textblock.Inlines.Add($Run)
					$uihash.textblock.Inlines.Add((New-Object System.Windows.Documents.LineBreak))

				}, "Send")
			$uihash.scrollviewer.Dispatcher.Invoke([action] {
					$uihash.scrollviewer.ScrollToEnd()
				}, "Send")
			$uihash.textblock.Dispatcher.Invoke([action] {
					$uihash.textblock.UpdateLayout()
				}, "Send")
			Write-Verbose -Message "$Sortabledate $ComputerName $Message1"
			IF ($PSBoundParameters['logfile']) {
				out-file "$($uihash.psscriptroot)\logs\$logfile" -input "$Sortabledate $ComputerName $Message1" -append #-enc ascii
			}
		}
	}

	End {}
}
Function ping-computer($computername) {

	if ($resultado = Test-Connection -ComputerName $computername -Count 2 -BufferSize 16 -quiet -erroraction "SilentlyContinue") {
		out-textblock -ComputerName $computername -Source "Test-connection" -Message "Online" -Messagetype 'OK' -logfile 'test-connection.log'
	}
	else {
		out-textblock -ComputerName $computername -Source "Test-connection" -Message "Offline" -Messagetype 'Error' -logfile 'test-connection.log'
		$computername = $null
	}
	return $computername
}
Function test-ports($computername, $ports) {

	$type = "OK"
	$checkedports = ""
	foreach ($port in $ports) {
		$socket = New-Object system.net.Sockets.TcpClient
		$connect = $socket.BeginConnect($computername, $port, $null, $null)
		#Configure a timeout before quitting - time in milliseconds
		$wait = $connect.AsyncWaitHandle.WaitOne(2000, $false)
		If (-Not $Wait) {
			#timeout
			$type = 'Error'
			$checkedports += "$port=timeout "
		}
		Else {
			try {
				$socket.EndConnect($connect)
				#open
				$checkedports += "$port=open "
			}
			Catch [system.exception] {
				#closed
				$type = 'Error'
				$checkedports += "$port=closed "
			}
		}
	}#fin foreach port
	if ($type -ne "OK") {$computername = $null}
	out-textblock -ComputerName $computername -Source "Test-ports" -Message $checkedports -MessageType $type -logfile 'test-ports.log'

	return $computername
}
Function Update-Window {
	Param (
		$Control,
		$Property,
		$Value,
		[switch]$AppendContent
	)

	# This is kind of a hack, there may be a better way to do this
	If ($Property -eq "Close") {
		$uihash.Window.Dispatcher.invoke([action] {$uihash.Window.Close()}, "Normal")
		Return
	}

	# This updates the control based on the parameters passed to the function
	$uihash.$Control.Dispatcher.Invoke([action] {
			# This bit is only really meaningful for the TextBox control, which might be useful for logging progress steps
			If ($PSBoundParameters['AppendContent']) {
				$uihash.$Control.AppendText($Value)
			}
			Else {
				$uihash.$Control.$Property = $Value
			}
		}, "Normal")
}
Function Show-Inputbox {
	Param([string]$message = $(Throw "You must enter a prompt message"),
		[string]$title = $uihash.tag,
		[string]$default
 )
	[reflection.assembly]::loadwithpartialname("microsoft.visualbasic") | Out-Null
	[microsoft.visualbasic.interaction]::InputBox($message, $title, $default)
}