$toSignFolder = Join-Path -Path $PSScriptRoot -ChildPath 'ToSign'
$signedFolder = Join-Path -Path $PSScriptRoot -ChildPath 'Signed'
$exist = Test-Path $signedFolder
if($exist -eq $false){
    md $signedFolder
}

$cert = (Get-ChildItem -Path cert:\LocalMachine\My\270b7c1804511a174fe9bc4abd06ec3ec3a80b42 )
$keyInfoX509Data = [System.Security.Cryptography.Xml.KeyInfoX509Data]::new($cert, [System.Security.Cryptography.X509Certificates.X509IncludeOption]::ExcludeRoot)
$xmlDocument = new-object Xml.XmlDocument
$xmlDocument.PreserveWhitespace = $true
add-type -AssemblyName system.security


Get-ChildItem $toSignFolder -Filter '*.xml' | foreach { 
    $env = New-Object System.Security.Cryptography.Xml.XmlDsigEnvelopedSignatureTransform
    $reference = New-Object System.Security.Cryptography.Xml.Reference
    $keyInfo = New-Object System.Security.Cryptography.Xml.KeyInfo
    $path = $_.FullName
    $xmlDocument.Load($path)
    $signedXml = New-Object System.Security.Cryptography.Xml.SignedXml -ArgumentList $xmlDocument
    $signedXml.SigningKey = $cert.PrivateKey

    $reference.Uri = ''
    $reference.AddTransform($env);
    $signedXml.AddReference($reference);


    $keyInfo.AddClause($keyInfoX509Data);
    $signedXml.KeyInfo = $keyInfo
        
    $signedXml.ComputeSignature()
        
    $xmldsigXmlElement = $signedXml.GetXml()

    $xmlDocument.DocumentElement.PrependChild($xmlDocument.ImportNode($xmldsigXmlElement, $true));
        
    $path = Join-Path -Path $signedFolder -ChildPath $_
    $xmlDocument.Save($path)
}

