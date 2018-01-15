﻿function Get-DbaPfDataCollector {
    <#
        .SYNOPSIS
            Gets Performance Monitor Data Collectors

        .DESCRIPTION
           Gets Performance Monitor Data Collectors

        .PARAMETER ComputerName
            The target computer. Defaults to localhost.

        .PARAMETER Credential
            Allows you to login to $ComputerName using alternative credentials.

        .PARAMETER CollectorSet
            The Collector Set name
  
        .PARAMETER Collector
            The Collector name
    
        .PARAMETER InputObject
            Enables piped results from Get-DbaPfDataCollectorSet

        .PARAMETER EnableException
            By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
            This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
            Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.
    
        .NOTES
            Tags: PerfMon

            Website: https://dbatools.io
            Copyright: (C) Chrissy LeMaire, clemaire@gmail.com
            License: GNU GPL v3 https://opensource.org/licenses/GPL-3.0
    
        .LINK
            https://dbatools.io/Get-DbaPfDataCollector

        .EXAMPLE
            Get-DbaPfDataCollector
    
            Gets all Collectors on localhost

        .EXAMPLE
            Get-DbaPfDataCollector -ComputerName sql2017
    
            Gets all Collectors on sql2017
    
        .EXAMPLE
            Get-DbaPfDataCollector -ComputerName sql2017, sql2016 -Credential (Get-Credential) -CollectorSet 'System Correlation'
    
            Gets all Collectors for 'System Correlation' Collector on sql2017 and sql2016 using alternative credentials
    
        .EXAMPLE
            Get-DbaPfDataCollectorSet -CollectorSet 'System Correlation' | Get-DbaPfDataCollector
    
            Gets all Collectors for 'System Correlation' Collector
    #>
    [CmdletBinding()]
    param (
        [DbaInstance[]]$ComputerName = $env:COMPUTERNAME,
        [PSCredential]$Credential,
        [string[]]$CollectorSet,
        [string[]]$Collector,
        [parameter(ValueFromPipeline)]
        [object[]]$InputObject,
        [switch]$EnableException
    )
    begin {
        $columns = 'ComputerName', 'DataCollectorSet', 'Name', 'DataCollectorType', 'DataSourceName', 'FileName', 'FileNameFormat', 'FileNameFormatPattern', 'LatestOutputLocation', 'LogAppend', 'LogCircular', 'LogFileFormat', 'LogOverwrite', 'SampleInterval', 'SegmentMaxRecords', 'Counters'
    }
    process {
        if ($InputObject.Credential -and (Test-Bound -ParameterName Credential -Not)) {
            $Credential = $InputObject.Credential
        }
        
        if (-not $InputObject -or ($InputObject -and (Test-Bound -ParameterName ComputerName))) {
            foreach ($computer in $ComputerName) {
                $InputObject += Get-DbaPfDataCollectorSet -ComputerName $computer -Credential $Credential -CollectorSet $CollectorSet
            }
        }
        
        if ($InputObject) {
            if (-not $InputObject.DataCollectorSetObject) {
                Stop-Function -Message "InputObject is not of the right type. Please use Get-DbaPfDataCollectorSet"
                return
            }
        }
        
        foreach ($set in $InputObject) {
            $collectorxml = ([xml]$set.Xml).DataCollectorSet.PerformanceCounterDataCollector
            foreach ($col in $collectorxml) {
                if ($Collector -and $Collector -notcontains $col.Name) { continue }
                
                $outputlocation = $col.LatestOutputLocation
                if ($outputlocation) {
                    $dir = ($outputlocation).Replace(':', '$')
                    $remote = "\\$($set.ComputerName)\$dir"
                }
                else {
                    $remote = $null
                }
                
                [pscustomobject]@{
                    ComputerName             = $set.ComputerName
                    DataCollectorSet         = $set.Name
                    Name                     = $col.Name
                    FileName                 = $col.FileName
                    DataCollectorType        = $col.DataCollectorType
                    FileNameFormat           = $col.FileNameFormat
                    FileNameFormatPattern    = $col.FileNameFormatPattern
                    LogAppend                = $col.LogAppend
                    LogCircular              = $col.LogCircular
                    LogOverwrite             = $col.LogOverwrite
                    LatestOutputLocation     = $col.LatestOutputLocation
                    RemoteLatestOutputLocation = $remote
                    DataSourceName           = $col.DataSourceName
                    SampleInterval           = $col.SampleInterval
                    SegmentMaxRecords        = $col.SegmentMaxRecords
                    LogFileFormat            = $col.LogFileFormat
                    Counters                 = $col.Counter
                    CounterDisplayNames      = $col.CounterDisplayName
                    CollectorXml             = $col
                    DataCollectorSetObject   = $set.DataCollectorSetObject
                    Credential               = $Credential
                } | Select-DefaultView -Property $columns
            }
        }
    }
}