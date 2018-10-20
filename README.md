# D3ploy
Powershell GUI to deploy your own scripts to remote computers.
This version is totally rewritten in WPF and run code in different runspaces to keep the GUI responsive.

![alt tag](https://2.bp.blogspot.com/-Vxr7pQMtFCo/W8tK27_4q0I/AAAAAAAACBs/bPtv13j61mYJ8-ijCWGmLjhUS_h2X2o8ACLcBGAs/s1600/D3ployGUIv3.png)

STEPS:
1. Choose the script you want to run from ScriptRepository
2. Write the computernames in Computers textbox or select txt file that contains them
3. Select proper credentials from the credentials combobox or write a description for new ones.
4. Choose whether you want to ping computers first, test the ports needed to work or do nothing
5. Run!

This GUI allows you to execute any script to a list of computers. The only thing you need to do is store your own batches and powershell scripts under 'ScriptRepository' folder.

When creating your own powershell scripts just bear in mind that the list of computers will fill the variable $computername and the credentials will be saved in $creds (PSCredential Object) and $credsplain (user and plain password object)
Here is an example for restarting a list of computers:

**restart-computer -computername $computername -credential $creds -force -confirm:$false**

I have uploaded some of my scripts and batches as examples.
Notice that underscore '_' character in scriptnames is used to create tree levels inside the GUI treeview in order to keep them organized.

More info about this project in:
https://systemswin.blogspot.com.es/2017/06/powershell-forms-deploy-batches-to.html

Enjoy!
