# Office365 Connector Cards

The [connector card](https://dev.outlook.com/Connectors/Reference) API is used for various things in Office365 connectors, but I wrote these functions for sending messages to the new Microsoft Teams.

This is the first draft. There's a lot of work needed to make the cmdlets _useable_. Maybe a few PSTypeNames, a couple of extra constructor functions, and some parameter sets to make sure that you only do things that make sense rendered.

For now, here are a couple examples in lieu of documentation. First, you must  configure it with the URL for your team -- captured from the Microsoft Teams Connectors configuration page:

```posh
Set-ConnectorUrl Forge Testing $TeamForgeTestingChannelUrl
```

Then you can send simple messages to the channel like this:

```posh
Send-Card -Group Forge -Channel Testing -Message "Hello World"
```

You can add an icon with three lines of text by adding a **section**:

```posh
$PesterImg = "http://pesterbdd.com/images/Pester.png"

Send-Card -Group Forge -Channel Testing -Message "Build Finished" -Sections (
    New-Section -Title "Pester Tests" -SubTitle "Pester Tests Succeeded" `
                -FullText "Code coverage **95%**." -AvatarUrl $PesterImg
)
```


And you can get much more creative, with _facts_ (displayed as a table) and _actions_ (a URL link, only one is _currently_ displayed per section, even through the API will accept a list of them). Note that you can always put links into the actual message, because all the non-title text fields support markdown.

```posh

$Pester = New-Section -SectionName "Pester Results" -Facts @{ 
    Passed = 2000
    Failed = 0
    Skipped = 3
} -AvatarUrl "http://pesterbdd.com/images/Pester.png" `
  -Title "Pester Tests" `
  -SubTitle "Pester Tests Succeeded" `
  -FullText "Pester tests _successful_, code coverage **95%**." 

Send-Card -Group Forge -Channel Testing -Title "Build Finished" -Message "Build succeeded" -Sections $Pester -Actions @{ 
    "See results in Web" = "http://google.com/"
}
```