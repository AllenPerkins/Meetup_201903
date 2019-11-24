<#
-------------------------------------------------------------------------------
Author: Allen Perkins
Date:   2019-02-26
Obj:    1. Read a list of URLs from a source file passed in as a parameter.
        2. Download the web page from each URL listed in that file.
        3. Parse the URL to create a unique file name.
        4. Save the downloaded web page using the parsed file name.
        5. Clean up the downloaded file leaving just the content.

        The file name with the list of URLs will be prefixed using a path
        defined in this script. See the variables section below to review or
        set the path to where the URL file is located.

        The command that is executed by the Invoke-Expression calls a bash
        script in the Windows Subsystem for Linux (WSL). It was demonstrated
        in a WSL environment running Ubuntu 18.04. That script must exist (
        (code is provided in the solution) with execute permissions.

-------------------------------------------------------------------------------
How to execute this script from the command line:
C:\>powershell -F BeigeBook.ps1 "URLList_2011-2016.txt"
C:\>powershell -F BeigeBook.ps1 "URLList_Test.txt"

-------------------------------------------------------------------------------
Revision history:

Date        Author            Purpose                                   TAG
-------------------------------------------------------------------------------
2019-02-26  Allen Perkins     Original (001.000.000)

-------------------------------------------------------------------------------
#>

<#
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

Load the parameters passed in via the command when this script was called.
Note: This must be the first step in a PowerShell script.

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
#>

Param
(
  [string]$URLList
)

<#
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

Script level variables.

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
#>

[string]$Path = 'C:\Users\APerkins\Documents\DataScience\Meetup_201903\Data\'
    # Change this path to point to where the URLList file is located.
[string]$URLFile = $Path + $URLList
    # The passed in parameter is concatenated with the path variable.
[string]$Command = ''
    # We will build a command string that will be invoked by reference.
[string]$ShellPath = '/mnt/c/Users/APerkins/Documents/'
        $ShellPath += 'DataScience/Meetup_201903/sh/'
[string]$ShellScript = 'GetBeigeBook.sh'
[string]$Shell = $ShellPath + $ShellScript
    # The $Command string includes the path and name of a shell script.
    # Be sure the shell script is located in that path.
[string]$URL = ''
[string[]]$File = @()
    # These two variables are iteratively updated as we loop through the
    # URLList file. They are used when we build the $Command variable.

# [string]$URL = 'https://www.federalreserve.gov/fomc/beigebook/2010/20101201/FullReport.htm'
# [string]$File = '201012.txt'


<#
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

Functions.

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
#>

Function Build-Command {
  <#
    Use the existing script level variables, some of which have just been
    created (e.g., URL and File), and build a string that will be used to
    execute a command that is external to PowerShell.
  #>
  $script:Command = 'bash -c '
#  $script:Command += "''/mnt/c/temp/parseHTML' '"
  $script:Command += "''" + $script:Shell + "' '"
  $script:Command += $script:URL
  $script:Command += "' '"
  $script:Command += $script:File
  $script:Command += "''"
}


<#
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

Process.

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
#>

try {

# URLs from 2011 to today.
If ($URLFile -match '2011-2019' -or $URLFile -match 'Test') {
  ForEach($URL in [System.IO.File]::ReadLines($URLFile)){
    # Build a file name from each URL that we read from the URLList.
    # We will save the URL contents in the file.
    $File = $URL.Split('beigebook')
      # Create an array with the each part either side of the split.
    $File = $File[-1]
      # Get the last element of the array.
    $File = $File.Replace('.htm','.txt')
      # Since we parsed a URL, the extension is .htm, change it to .txt.
    Write-Host $File, $URL
    Build-Command
      # Call the function we defined above. It will update the script-level
      # variable named $Command.
    Write-Host $Command
    Invoke-Expression $Command
  }
}

# URLs from 2009-2010. The URL format differed 8 years ago.
ElseIf ($URLFile -match '2009-2010') {
  ForEach($URL in [System.IO.File]::ReadLines($URLFile)){
    # Build a file name from the URL.
    # We will save the URL contents in the file.
    $File = $URL.Split('/FullReport.htm') -ne ""
      # Create an array with the each part either side of the split.
      # NB: We are slicing off the end of the URL because the month and
      # year of the report is part of the virtual directory path.
    $File = $File[-1].SubString(0,6)
      # Get the last element of the array [-1].
      # Get the left most six characters (0,6).
    $File = $File.trim() + '.txt'
      # Add an extension to the name pulled from the middle of the URL.
    Write-Host $File, $URL
    Build-Command
    Write-Host $Command
    Invoke-Expression $Command
  }
}

# We do not have a parser for the requeted URLList file.
Else {
  Write-Host 'URLList file could not be parsed.'
}

}
catch {
  $ErrorMsg = 'We are in the catch block. Here is the stack: '
  $ErrorMsg += "Exception at: $($PSItem.ScriptStackTrace)"
  $ErrorMsg += "Exception Type: $($_.Exception.GetType().FullName)"
  $ErrorMsg += "Exception Message: $($_.Exception.Message)"
  Write-Host $ErrorMsg
}
