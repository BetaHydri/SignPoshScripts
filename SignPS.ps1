<#
.SYNOPSIS
    WPF GUI tool to sign PowerShell scripts with a code-signing certificate.

.DESCRIPTION
    Presents a WPF window that lets the user browse for PowerShell files,
    select a code-signing certificate from the Windows certificate store or
    a connected smart card, and apply Authenticode signatures (SHA-256) with
    a DigiCert timestamp.

.AUTHOR
    Jan Tiedemann

.DATE
    2026

.LINK
    https://github.com/BetaHydri/SignPoshScripts
#>

$XAML = @'

<Window x:Name="MainWindows" 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApp1"
        mc:Ignorable="d"
        Title="Certificate Code Signing Tool" Height="540" Width="894" ResizeMode="NoResize">
    <Grid x:Name="MainWindow1" Margin="0,0,-20.333,-19">
        <Grid.RowDefinitions>
            <RowDefinition Height="82*"/>
            <RowDefinition Height="399*"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="409*"/>
            <ColumnDefinition Width="77*"/>
            <ColumnDefinition Width="154*"/>
            <ColumnDefinition Width="155*"/>
            <ColumnDefinition Width="73*"/>
            <ColumnDefinition Width="27*"/>
        </Grid.ColumnDefinitions>
        <GroupBox x:Name="CertInfoGroupBox" Grid.ColumnSpan="4" Grid.Column="1" Header="Certificate Info:" Height="252" Margin="9.667,64,12.333,0" Grid.RowSpan="2" VerticalAlignment="Top" RenderTransformOrigin="0.5,0.5">
            <GroupBox.RenderTransform>
                <TransformGroup>
                    <ScaleTransform/>
                    <SkewTransform/>
                    <RotateTransform Angle="0.213"/>
                    <TranslateTransform/>
                </TransformGroup>
            </GroupBox.RenderTransform>
        </GroupBox>
        <Button VerticalAlignment="Bottom" x:Name="Browse" Content="Browse..." RenderTransformOrigin="1.797,2.286" Height="35" FontSize="10" Margin="11.667,0,0,33.333" Grid.ColumnSpan="2" Grid.Row="1" Grid.Column="1" Width="120" HorizontalAlignment="Left"/>
        <Button x:Name="Sign" Content="Sign" IsEnabled="False" RenderTransformOrigin="-0.219,0.514" FontSize="10" Margin="90.667,0,0,33.333" Grid.ColumnSpan="2" Grid.Column="2" Grid.Row="1" Width="120" Height="35" HorizontalAlignment="Left" VerticalAlignment="Bottom" />
        <Button x:Name="Close" Content="Close" IsCancel="True" Margin="99.667,0,0,33.333" Grid.Column="3" Grid.Row="1" Grid.ColumnSpan="2" Width="120" Height="35" FontSize="10" HorizontalAlignment="Left" VerticalAlignment="Bottom" />
        <ComboBox x:Name="ComboBox1" Margin="11.667,30,10.333,23" Grid.ColumnSpan="4" Grid.Column="1"/>
        <TextBlock HorizontalAlignment="Left" Margin="10.667,10,0,0" TextWrapping="Wrap" VerticalAlignment="Top" RenderTransformOrigin="0.467,1.629" Height="18" Width="200" Grid.ColumnSpan="2" Grid.Column="1"><Run Text="Choose Code"/><Run Text=" "/><Run Text="Signing"/><Run Text=" "/><Run Text="Certificate"/><Run Text=":"/></TextBlock>
        <ListView x:Name="List1" HorizontalAlignment="Left" Margin="10,30,0,0" Width="400" Height="365" VerticalAlignment="Top" Grid.RowSpan="2" Grid.ColumnSpan="2">
            <ListView.View>
                <GridView>
                    <GridViewColumn/>
                </GridView>
            </ListView.View>
        </ListView>
        <Label Content="Choose your files to sign:" HorizontalAlignment="Left" Margin="10,5,0,0" VerticalAlignment="Top" Width="150" Height="30"/>
        <TextBox x:Name="Message" Grid.ColumnSpan="4" Grid.Column="1" Height="231" Margin="16.667,0,18.333,0" TextWrapping="Wrap" VerticalAlignment="Top" Grid.Row="1" RenderTransformOrigin="0.5,0.5" FontSize="10">
            <TextBox.RenderTransform>
                <TransformGroup>
                    <ScaleTransform/>
                    <SkewTransform/>
                    <RotateTransform Angle="-0.05"/>
                    <TranslateTransform/>
                </TransformGroup>
            </TextBox.RenderTransform>
        </TextBox>
        <GroupBox x:Name="NotificationGroupBox" Grid.ColumnSpan="4" Grid.Column="1" Header="Notifications:" Height="82" Margin="10.667,235,12.333,0" Grid.Row="1" VerticalAlignment="Top" BorderBrush="#FFFF1700">
            <TextBox x:Name="Notification" Height="57" Margin="0,0,3,0" TextWrapping="Wrap" VerticalAlignment="Top" RenderTransformOrigin="0.5,0.5" FontSize="10"/>
        </GroupBox>
        <TextBlock Text="Timestamp Server:" HorizontalAlignment="Left" Margin="11.667,322,0,0" Grid.ColumnSpan="4" Grid.Column="1" Grid.Row="1" VerticalAlignment="Top" Height="16" FontSize="10"/>
        <TextBox x:Name="TimestampServer" Text="http://timestamp.digicert.com" IsReadOnly="True" Grid.ColumnSpan="4" Grid.Column="1" Margin="11.667,340,40.333,0" Grid.Row="1" VerticalAlignment="Top" Height="22" FontSize="10" Background="#FFF0F0F0"/>
        <Button x:Name="TimestampConfig" Content="&#x2699;" Grid.ColumnSpan="4" Grid.Column="1" Margin="0,340,12.333,0" Grid.Row="1" VerticalAlignment="Top" Height="22" Width="24" FontSize="12" HorizontalAlignment="Right" ToolTip="Configure timestamp server"/>

    </Grid>
</Window>

'@

function Convert-XAMLtoWindow {
  param
  (
    [Parameter(Mandatory = $true)]
    [string]
    $XAML
  )
  
  Add-Type -AssemblyName PresentationFramework
  
  $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
  $result = [Windows.Markup.XAMLReader]::Load($reader)
  $reader.Close()
  $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
  while ($reader.Read()) {
    $name = $reader.GetAttribute('Name')
    if (!$name) { $name = $reader.GetAttribute('x:Name') }
    if ($name)
    { $result | Add-Member NoteProperty -Name $name -Value $result.FindName($name) -Force }
  }
  $reader.Close()
  $result
}

function Show-WPFWindow {
  param
  (
    [Parameter(Mandatory)]
    [Windows.Window]
    $Window
  )
  
  $result = $null
  $null = $window.Dispatcher.InvokeAsync{
    $result = $window.ShowDialog()
    Set-Variable -Name result -Value $result -Scope 1
  }.Wait()
  $result
}

function Get-Files {
  if ($window.List1.SelectedIndex -ne -1) {
    $filenames = $window.List1.SelectedItems
    return $filenames
  }
  else { 
    Write-Verbose -Message ("Please select your files to sign")
    $window.Notification.Text = "You have to select at least one file to sign"
  }
}

function Get-CertificateKeyProviderName {
  # Legacy CSP exposes the provider via CspKeyContainerInfo; CNG keys do not, so probe both.
  param
  (
    [Parameter(Mandatory = $true)]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
    $Certificate
  )

  if (-not $Certificate.HasPrivateKey) { return $null }

  # CNG Key Storage Providers (e.g. "Microsoft Smart Card Key Storage Provider")
  try {
    $rsaCng = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Certificate)
    if ($rsaCng -is [System.Security.Cryptography.RSACng]) {
      return $rsaCng.Key.Provider.Provider
    }
  }
  catch { }

  try {
    $ecdsaCng = [System.Security.Cryptography.X509Certificates.ECDsaCertificateExtensions]::GetECDsaPrivateKey($Certificate)
    if ($ecdsaCng -is [System.Security.Cryptography.ECDsaCng]) {
      return $ecdsaCng.Key.Provider.Provider
    }
  }
  catch { }

  # Legacy CSP providers (e.g. "Microsoft Base Smart Card Crypto Provider")
  try {
    if ($Certificate.PrivateKey -and $Certificate.PrivateKey.CspKeyContainerInfo) {
      return $Certificate.PrivateKey.CspKeyContainerInfo.ProviderName
    }
  }
  catch { }

  return $null
}

function Get-CodeSigningCertificatesFromSmartCard {
  try {
    # Load the smartcard reader
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store "My", "CurrentUser"
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)

    foreach ($cert in $store.Certificates) {
      if (-not $cert.HasPrivateKey) { continue }

      # Keep only certs whose private key lives on a smart card (CSP or CNG provider)
      $providerName = Get-CertificateKeyProviderName -Certificate $cert
      if (-not $providerName -or $providerName -notlike '*Smart Card*') { continue }

      # Check if the certificate has the code signing usage
      foreach ($extension in $cert.Extensions) {
        if ($extension -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]) {
          $usages = $extension.EnhancedKeyUsages
          foreach ($usage in $usages) {
            if ($usage.FriendlyName -eq "Code Signing" -or $usage.Value -eq "1.3.6.1.5.5.7.3.3") {
              Write-Output $cert
            }
          }
        }
      }
    }

    # Close the store
    $store.Close()
  }
  catch {
    Write-Error "An error occurred: $_"
  }
}
function Invoke-SignFile ([Parameter(Mandatory = $true)]$filename) {
  try {
    $thumbprint = $script:mycodesigningcerts[($window.ComboBox1.SelectedIndex)].Thumbprint
    $mycert = Get-ChildItem("Cert:\CurrentUser\my\$thumbprint")
    Set-AuthenticodeSignature -FilePath $filename `
      -Certificate $mycert `
      -TimestampServer $window.TimestampServer.Text `
      -IncludeChain All `
      -HashAlgorithm SHA256
    Write-Verbose -Message ("File {0} signed" -f $filename)
    $window.Notification.Text += "File: {0} have been signed`n" -f $filename.Name
  }
  catch { 
    Write-Verbose -Message ("Error: {0}" -f $_.Exception.Message)
    $window.Notification.Text = "Error: {0}`n" -f $_.Exception.Message
  } 
}

$window = Convert-XAMLtoWindow -XAML $XAML
$script:mycodesigningcerts = @()

$window.Close.add_Click{
  # remove param() block if access to event information is not required
  
  exit
}

$window.TimestampConfig.add_Click{
  $dialog = New-Object Windows.Window
  $dialog.Title = 'Configure Timestamp Server'
  $dialog.Width = 500
  $dialog.Height = 150
  $dialog.WindowStartupLocation = 'CenterOwner'
  $dialog.Owner = $window
  $dialog.ResizeMode = 'NoResize'

  $stackPanel = New-Object Windows.Controls.StackPanel
  $stackPanel.Margin = '10'

  $label = New-Object Windows.Controls.TextBlock
  $label.Text = 'Timestamp Server URL:'
  $label.Margin = '0,0,0,5'
  [void]$stackPanel.Children.Add($label)

  $urlTextBox = New-Object Windows.Controls.TextBox
  $urlTextBox.Text = $window.TimestampServer.Text
  $urlTextBox.Margin = '0,0,0,10'
  [void]$stackPanel.Children.Add($urlTextBox)

  $buttonPanel = New-Object Windows.Controls.StackPanel
  $buttonPanel.Orientation = 'Horizontal'
  $buttonPanel.HorizontalAlignment = 'Right'

  $okButton = New-Object Windows.Controls.Button
  $okButton.Content = 'OK'
  $okButton.Width = 75
  $okButton.Margin = '0,0,10,0'
  $okButton.IsDefault = $true
  $okButton.add_Click{
    $window.TimestampServer.Text = $urlTextBox.Text
    $dialog.Close()
  }
  [void]$buttonPanel.Children.Add($okButton)

  $cancelButton = New-Object Windows.Controls.Button
  $cancelButton.Content = 'Cancel'
  $cancelButton.Width = 75
  $cancelButton.IsCancel = $true
  [void]$buttonPanel.Children.Add($cancelButton)

  [void]$stackPanel.Children.Add($buttonPanel)
  $dialog.Content = $stackPanel
  [void]$dialog.ShowDialog()
}

$window.Browse.add_Click{

  # Clear Forms in UI
  $window.List1.items.Clear()
  $window.ComboBox1.Items.Clear()
  $script:mycodesigningcerts = @()
  
  Add-Type -AssemblyName System.Windows.Forms
  $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    Multiselect = $true # Multiple files can be chosen
    Filter      = 'PowerShell (PowerShell (*.ps*)|*.ps*;*.ps1xml|All Files (*.*)|*.*' # Specified file types
  }

  [void]$FileBrowser.ShowDialog()

  $path = $FileBrowser.FileNames

  if ($FileBrowser.FileNames -like "*\*") {

    # Do something before work on individual files commences
    foreach ($file in Get-ChildItem $path) {
      # add filepath to the ListBox List1
      Get-ChildItem ($file) |
      ForEach-Object {
        $window.List1.items.Add($file)
      }
    }
    # Collect code signing certs from user store and smartcard, deduplicate by thumbprint
    $storeCerts = @(Get-ChildItem cert:\currentuser\my -CodeSigningCert)
    $smartCardCerts = @(Get-CodeSigningCertificatesFromSmartCard)
    $seen = @{}
    $allCerts = @($storeCerts) + @($smartCardCerts) | Where-Object {
      $_ -and -not $seen.ContainsKey($_.Thumbprint)
    } | ForEach-Object {
      $seen[$_.Thumbprint] = $true
      $_
    }

    $now = Get-Date
    foreach ($cert in $allCerts) {
      if ($cert.NotAfter -gt $now) {
        $window.ComboBox1.Items.Add($cert.Subject)
        $script:mycodesigningcerts += $cert
      }
      else {
        Write-Verbose -Message ('Certificate expired: {0}' -f $cert.Subject)
        $window.Notification.Text = "Certificate:`n{0}`nwith Thumbprint {1}`nis expired and has been skipped" -f $cert.Subject, $cert.Thumbprint
      }
    }

    if ($script:mycodesigningcerts.Count -eq 0) {
      $window.Message.Text = 'No valid code signing certificates have been found!'
    }
    else {
      $window.ComboBox1.SelectedIndex = 0
    }
   
  }

  else {
    Write-Verbose -Message ("Cancelled by user")
  }
}

$window.ComboBox1.add_SelectionChanged{
  
  # add event code here
  if ($window.ComboBox1.SelectedItem) {
    $window.Sign.IsEnabled = $true
    $window.Message.Text = $script:mycodesigningcerts[($window.ComboBox1.SelectedIndex)]
  }
}

$window.Sign.add_Click{
  $window.Notification.Text = ""
  
  # add event code here
  $files = Get-Files
  #$signcert = @($window.ComboBox1.SelectedItem)
  #Write-Host $global:mycodesigningcerts[(($window.ComboBox1.SelectedIndex))]
  foreach ($file in $files) {
    #Set-AuthenticodeSignature -Certificate $global:mycodesigningcerts[($window.ComboBox1.SelectedIndex)] -FilePath $file
    try {
      Invoke-SignFile $file
    }
    catch {
      Write-Verbose -Message ("File {0} not signed, error was {1}" -f $file, $_.Exception.Message)
      $window.Notification.Text += "File: {0} not signed`nError: {1}" -f $file.Name, $_.Exception.Message
    }
  }
}

Show-WPFWindow -Window $window
