function Get-SCOMNotifications {
    param([parameter()][switch]$Debugging)
    if ($Debugging.IsPresent) { Write-Host Debugging is turned on }
    
    import-module dps

    Connect-SCOMprod | out-null

    # Retrieve Channel Detail and store in an object to export then build add from this detail
    $arrChannel = @()
    $hashChannel = @{}
    foreach ($chan in (Get-SCOMNotificationChannel | sort DisplayName)) {
        $obj = New-Object System.Object
        $obj | Add-Member -type NoteProperty -Name DisplayName -Value $chan.DisplayName
        $obj | Add-Member -type NoteProperty -Name ChannelType -Value $chan.ChannelType
        $obj | Add-Member -type NoteProperty -Name Action -Value $chan.Action.Name
        foreach ($detail in ($chan.action) ) {
            $obj | Add-Member -type NoteProperty -Name Description -Value $detail.Description
            $obj | Add-Member -type NoteProperty -Name ActionID -Value $detail.Id
            if ($chan.ChannelType -eq "Command") {
                $obj | Add-Member -type NoteProperty -Name ApplicationName -Value $detail.ApplicationName
                $obj | Add-Member -type NoteProperty -Name WorkingDirectory -Value $detail.WorkingDirectory
                $obj | Add-Member -type NoteProperty -Name CommandLine -Value $detail.CommandLine
            }
            if ($chan.ChannelType -eq "Smtp") {
                $obj | Add-Member -type NoteProperty -Name From -Value $detail.From
                $obj | Add-Member -type NoteProperty -Name Subject -Value $detail.Subject
                $obj | Add-Member -type NoteProperty -Name Body -Value $detail.Body
                $obj | Add-Member -type NoteProperty -Name IsBodyHtml -Value $detail.IsBodyHtml
            }
        }
        $arrChannel += $obj 
        $hashChannel[$chan.Action.Name] = $obj
    }

    # retrieve the subscriber details.  
    $arrSubscriber = @();
    foreach ($subsc in (Get-SCOMNotificationSubscriber | sort Name)) {
        $obj = New-Object System.Object
        $obj | Add-Member -type NoteProperty -Name Name -Value $subsc.Name
        $obj | Add-Member -type NoteProperty -Name Id -Value $subsc.Id
        $obj | Add-Member -type NoteProperty -Name Devices -Value $subsc.Devices
        $obj | Add-Member -type NoteProperty -Name ScheduleEntries -Value $subsc.ScheduleEntries
        $obj | Add-Member -type NoteProperty -Name DeviceName -Value $subsc.Devices.Name
        $obj | Add-Member -type NoteProperty -Name DeviceProtocol -Value $subsc.Devices.Protocol
        $obj | Add-Member -type NoteProperty -Name DeviceAddress -Value $subsc.Devices.Address
        $arrSubscriber += $obj
        # Link subscriber to channel
        # $arrSubscriber[1]; $arrChannel|?{$_.Action -match $arrSubscriber[1].DeviceProtocol}
        # $hashChannel[$subsc.Devices.Protocol]
    }

    # Subscription details setup

    # Severity values
    $sev = @{}
    $sev[2] = "Critical"
    $sev[1] = "Warning"
    $sev[0] = "Information"

    # Priority values
    $pri = @{}
    $pri[2] = "High"
    $pri[1] = "Medium"
    $pri[0] = "Low"

    # Resolution States
    $res = @{}
    Get-SCOMAlertResolutionState | % { $res[$_.ResolutionState] = $_.Name }

    # parse subscrition criteria
    function get-Criteria($criteria) {		
        $x = $Criteria.SimpleExpression
        $Property = $x.ValueExpression.Property;
        $Operator = $x.Operator;
        $Value = $x.ValueExpression.Value
        if ($Operator) { 
            "$($sub.DisplayName) : $Property $Operator $Value" 
            ##Property: ProblemId, ruleId, Priority, Severity, ResolutionState, AlertName(regx)
            if ($Property -eq "ProblemId") { (Get-SCOMMonitor -Id $Value).DisplayName }
            elseif ($Property -eq "RuleId") { (Get-SCOMRule -Id $Value).DisplayName }
            elseif ($Property -eq "Priority") { $pri[$Value] }
            elseif ($Property -eq "Severity") { $sev[$Value] }
            elseif ($Property -eq "ResolutionState") { $res[$Value] }
            elseif ($Property -eq "AlertName") { $Value }
            else { "Unhandled Property: $property" }
        }
    }

    # Retrieve the subscription details
    $arrSubscriptions = @()
    foreach ($sub in (Get-SCOMNotificationSubscription | sort DisplayName)) {
        $obj = New-Object System.Object
        $obj | Add-Member -type NoteProperty -Name Name -Value $sub.Name
        $obj | Add-Member -type NoteProperty -Name DisplayName -Value $sub.DisplayName
        $obj | Add-Member -type NoteProperty -Name Description -Value $sub.Description
        $obj | Add-Member -type NoteProperty -Name Actions -Value $sub.Actions
        $obj | Add-Member -type NoteProperty -Name ToRecipients -Value $sub.ToRecipients
        $obj | Add-Member -type NoteProperty -Name ConfigurationCriteria -Value $sub.Configuration.Criteria
        $GroupId = $sub.configuration.MonitoringObjectGroupIds.Guid
        if ($GroupId) {
            $obj | Add-Member -type NoteProperty -Name GroupId -Value $GroupId
            $GroupName = (Get-SCOMGroup -Id $GroupId).DisplayName
            $obj | Add-Member -type NoteProperty -Name GroupDisplayName -Value $GroupName
        }
        else {
            $obj | Add-Member -type NoteProperty -Name GroupId -Value ""
            $obj | Add-Member -type NoteProperty -Name GroupDisplayName -Value ""
        }
        # Actions / Channels
        if ($sub.Actions.Count -gt 1) {
            #if ($Debugging.IsPresent) { Write-Host NOTE: Actions::    $($obj.DisplayName) : Multiple Actions details } #$sub.Actions.Name
            Write-Host NOTE: Actions::    $($obj.DisplayName) : Multiple Actions details 
            ##### Handle multiple $subActions #####
            $obj | Add-Member -type NoteProperty -Name ActionsNames -Value $sub.Actions.Name
        }
        else {
            foreach ($detail in ($sub.Actions) ) {
                $obj | Add-Member -type NoteProperty -Name ActionChannelType -Value ($hashChannel[$detail.Name]).ChannelType
                $obj | Add-Member -type NoteProperty -Name ActionDisplayName -Value $detail.DisplayName
                $obj | Add-Member -type NoteProperty -Name ActionName -Value $detail.Name
                $obj | Add-Member -type NoteProperty -Name ActionDescription -Value $detail.Description
                $obj | Add-Member -type NoteProperty -Name ActionID -Value $detail.Id
                if (($hashChannel[$detail.Name]).ChannelType -eq "Command") {
                    $obj | Add-Member -type NoteProperty -Name ActionApplicationName -Value $detail.ApplicationName
                    $obj | Add-Member -type NoteProperty -Name ActionWorkingDirectory -Value $detail.WorkingDirectory
                    $obj | Add-Member -type NoteProperty -Name ActionCommandLine -Value $detail.CommandLine
                }
                if (($hashChannel[$detail.Name]).ChannelType -eq "Smtp") {
                    $obj | Add-Member -type NoteProperty -Name SmtpFrom -Value $detail.From
                    $obj | Add-Member -type NoteProperty -Name SmtpSubject -Value $detail.Subject
                    $obj | Add-Member -type NoteProperty -Name SmtpBody -Value $detail.Body
                    $obj | Add-Member -type NoteProperty -Name SmtpIsBodyHtml -Value $detail.IsBodyHtml
                }
            }
        }
	
        # Subscribers
        if ($sub.Torecipients.Count -gt 1) {
            Write-Host NOTE: Recipients:: $($obj.DisplayName) : Multiple Torecipients details   #$sub.Torecipients.Name 
            ##### Handle multiple $sub.Torecipients #####
        }
        else {
            foreach ($subscriber in $sub.Torecipients) {
                $obj | Add-Member -type NoteProperty -Name SubscriberName -Value $subscriber.Name
                $obj | Add-Member -type NoteProperty -Name SubscriberId -Value $subscriber.Id.Guid
                #$obj | Add-Member -type NoteProperty -Name SubscriberDevices -Value $subsc.Devices
                $obj | Add-Member -type NoteProperty -Name SubscriberScheduleEntries -Value $subscriber.ScheduleEntries
                $obj | Add-Member -type NoteProperty -Name SubscriberDeviceName -Value $subscriber.Devices.Name
                $obj | Add-Member -type NoteProperty -Name SubscriberDeviceProtocol -Value $subscriber.Devices.Protocol
                $obj | Add-Member -type NoteProperty -Name SubscriberDeviceAddress -Value $subscriber.Devices.Address
            }
        }
	
        $arrSubscriptions += $obj
        #property, Operator, Value
        #$xml=[xml]$arrSubscriptions[108].Configuration.Criteria
        $xml = [xml]$obj.Configuration.Criteria
        foreach ($criteria in ($xml.And.Expression)) {
            #Get-Criteria $criteria
        }
	
        if (($xml.And.Expression.Or.Expression).Count -gt 0) {
            #"<OR>"
            foreach ($OrCriteria in ($xml.And.Expression.Or.Expression)) {
                #	Get-Criteria $OrCriteria
            }
            #"</OR>"		
        }
        #Remove-Variable OrProperty, OrOperator, OrValue, Property, Operator, Value, xs, xors	
    }

    # Subscriptions with blank groups
    if ($Debugging.IsPresent) { Write-Host Subscriptions with blank groups }
    #if ($Debugging.IsPresent) { $arrSubscriptions | Select-Object DisplayName, GroupId, GroupDisplayName | Where-Object { $_.GroupId.length -gt 0 -and $_.GroupDisplayName.Length -eq 0 } }
    if ($Debugging.IsPresent) { Write-Host "$($arrSubscriptions | Select-Object DisplayName, GroupId, GroupDisplayName | Where-Object { $_.GroupId.length -gt 0 -and $_.GroupDisplayName.Length -eq 0 } |Out-String)" }
    if (!$Debugging.IsPresent) { return $arrSubscriptions }
}
# . "E:\OneDrive - WellSpan Health\SourceCode\dpsmodule\Source\Public\Get-SCOMNotifications.ps1"