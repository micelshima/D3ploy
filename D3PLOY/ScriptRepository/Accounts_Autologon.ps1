if ($scope -eq '') {$params = @{'computername' = $computername}
}
else {$params = @{'computername' = $computername; 'credential' = $creds}
}
$block={
New-ItemProperty -name AutoAdminLogon -PropertyType string –path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -value '1' -force
New-ItemProperty -name DefaultDomainName -PropertyType string –path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -value 'BETA' -force
New-ItemProperty -name DefaultUserName -PropertyType string –path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -value 'AdminPrimavera' -force
New-ItemProperty -name DefaultPassword -PropertyType string –path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -value 'Acciona2022' -force
}
Invoke-Command @params -scriptblock $block
