<#

.NOTES
 
Nom du fichier 		: servProc.ps1
Prérequis 		    : PowerShell 7.4.0
Version du script 	: 1.0
Auteur 			    : Mateja Velickovic
Date de creation 	: 15.12.2023
Lieu 			    : ETML, Sebeillion
Changement 		    : Aucun
 
.SYNOPSIS
Script qui permet le controle des processus et des services
sur une machine distante.
 
.DESCRIPTION
Le controle des services et des processus se fait sur la base 
d'un fichier CSV qui contient les services ainsi que les 
processus autorises a etre executes, si un des service ou 
processus n'est pas autorise, un message est affiche est 
l'utilisateur aura le choix de l'autoriser ou bien de l'arreter.
 
.PARAMETER ComputerName
Nom de la machine distante
 
.PARAMETER User
Nom d'utilisateur distant
 
.PARAMETER UserPS
Mot de passe de l'utilisateur distant

.INPUTS
-
 
.OUTPUTS
-
 
.EXAMPLE
PS> extension -name "File"
File.txt
 
.LINK
-

#>

param(
    [Parameter(Mandatory = $true)]
    [string[]]$ComputerName,

    [Parameter(Mandatory = $true)]
    [string[]]$User,

    [Parameter(Mandatory = $true)]
    [string[]]$UserPS
)

# Conversion en secureString du mot de passe
$password = ConvertTo-SecureString -String "$UserPS" -AsPlainText -Force

# Nom d'utilisateur
$username = $User

# Remplissage automatique du formulaire credential avec les informations passees en parametres
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password

# Configuration du type de resseau -> prive (le type de reseau distant doit aussi l'etre !)
if ((Get-NetConnectionProfile).NetWorkCategory -eq "Public") {
    $index = (Get-NetConnectionProfile).InterfaceIndex
    Set-NetConnectionProfile -InterfaceIndex $index -NetWorkCategory Private
}

# Mise à jour des processus en cours d'execution sur la machine distance & exporation de ces derniers dans un fichier CSV
$getProcess = 
Invoke-Command -ComputerName $computerName -Credential $credential -ScriptBlock {
    $process = Get-Process | Select-Object Name, ID 
    $process
}
$getProcess | Export-Csv -Path actProc.csv -NoTypeInformation

# Mise à jour des processus en cours d'execution sur la machine distance & exporation de ces derniers dans un fichier CSV
$getService = 
Invoke-Command -ComputerName $computerName -Credential $credential -ScriptBlock {
    $service = Get-Service | Select-Object Name, Status 
    $service
}
$getService | Export-Csv -Path actServ.csv -NoTypeInformation

# Comparaison des procesus
$allowedProc = Import-Csv -Path .\authProc.csv
$currentProc = Import-Csv -Path .\actProc.csv

# Comparaison des services
$allowedServ = Import-Csv -Path .\authServ.csv
$currentServ = Import-Csv -Path .\actServ.csv

# Lancement du programme
Clear-Host

$currentDate = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
Write-Host "`n GESTIONNAIRE DE SERVICES & PROCESSUS SUR LA MACHINE : $ComputerName" -ForegroundColor Yellow

# Comparaison des processus & services autorises, affichage de ceux qui ne sont pas autorises
Write-Host "`n [!] Processus detectes qui ne sont pas autorises :" -ForegroundColor DarkRed
Compare-Object $allowedProc -DifferenceObject $currentProc -IncludeEqual -Property Name  | Where-Object { $_.SideIndicator -eq "=>" } | Format-Wide -Column 4 | Out-Host

Write-Host " [!] Services detectes qui ne sont pas autorises :" -ForegroundColor DarkRed
Compare-Object $allowedServ -DifferenceObject $currentServ -IncludeEqual -Property Name  | Where-Object { $_.SideIndicator -eq "=>" } | Format-Wide -Column 4 | Out-Host


# Autorisation & arret des services/processus voulus

$actionList = @'
Que voulez-vous faire ?
 [A]utoriser un processus/service
 [S]topper un service
 [D]emarrer un service
 [Q]uitter 
'@
$allowServProc = Read-Host $actionList
switch ($allowServProc) {

    'A' {

        $whichServProc = Read-Host " [?] Quel service/processus voulez vous autoriser ? "

        # Verifier c'est un processus
        Get-Process $whichServProc 2>$null | Out-Null
        if ($?) {
        
            # Recuperation des informations du processus selectionne
            $getAllowedProc =
            Invoke-Command -ComputerName $computerName -Credential $credential -ScriptBlock {
        
                # Ajout du $using: pour que la session reconnaisse notre variable
                $process = Get-Process -Name $using:whichservproc | Select-Object Name, ID 
                $process
        
            }
                    
            # Creation du fichier qui contient les informations du processus selectionne
            $getAllowedProc | Export-Csv -Path ".\$whichServProc.csv" -Force -NoTypeInformation
        
            # Ajout du processus dans le fichier avec l'encodage ASCII
            $procContent = Get-Content ".\$whichServProc.csv"
            $procContent | Out-File .\authProc.csv -Append -Encoding ASCII
        
            if ($?) {
                Write-Host " [+] Le processus $whichServProc a ete correctement ajoute a la liste des processus autorises" -ForegroundColor DarkGreen
            }
        
            Remove-Item ".\$whichServProc.csv"
        
        }

        # Verifier si c'est un service
        Get-Service $whichServProc 2>$null | Out-Null
        if ($?) {
        
            # Recuperation des informations du processus selectionne
            $getAllowedServ =
            Invoke-Command -ComputerName $computerName -Credential $credential -ScriptBlock {
        
                # Ajout du $using: pour que la session reconnaisse notre variable
                $service = Get-Service -Name $using:whichservproc | Select-Object Name, Status 
                $service
        
            }
                    
            # Creation du fichier qui contient les informations du service selectionne
            $getAllowedServ | Export-Csv -Path ".\$whichServProc.csv" -Force -NoTypeInformation
        
            # Ajout du service dans le fichier avec l'encodage ASCII
            $servContent = Get-Content ".\$whichServProc.csv"
            $servContent | Out-File .\authServ.csv -Append -Encoding ASCII
        
            if ($?) {
                Write-Host " [+] Le service $whichServProc a ete correctement ajoute a la liste des services autorises" -ForegroundColor DarkGreen
            }
        
            Remove-Item ".\$whichServProc.csv"
        
        }

    }

    'S' {

    }

    Default {
        Exit
    }
}