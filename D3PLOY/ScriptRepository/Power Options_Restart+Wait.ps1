if ($scope -eq '') {$params = @{'computername' = $computername}
}
else {$params = @{'computername' = $computername; 'credential' = $creds}
}
restart-computer @params -force -confirm:$false -Wait -For Wmi -Delay 6