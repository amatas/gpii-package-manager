
$ErrorActionPreference = 'Stop'; # stop on all errors

$packageName = 'gpii' # arbitrary name for the package, used in messages
$url = 'http://choco.gpii.es/msi-packages/gpii-installer_1.0.1.msi' # download url
$Arguments = '/qn /norestart'
$packateType = 'msi'
$checksum = '__CHECKSUM_OF_MSI_HERE__' 
$checksumType = 'md5'

Install-ChocolateyPackage $packageName $packateType $Arguments $url -checksum $checksum -checksumType $checksumType
