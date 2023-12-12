# Show-Services : Affichage des services $IsRunning en $Columns colonnes 
function Show-Services {

    param(
        [Parameter(Mandatory = $false)]
        [boolean]$IsRunning,

        [Parameter(Mandatory = $true)]
        [int]$Columns
    )

    $displayColumns = $Columns 

    if ($IsRunning) {
        $status = "Running" 
        $color = "Green"

    }
    else {
        $status = "Stopped"
        $color = "Red"

    }

    # Signifie que les messages d'erreurs (représentés par le canal d'erreur numéro 2) seront ignorés
    $services = Get-Service 2>$null | Where-Object { $_.Status -eq $status } | Format-Wide -Column $displayColumns
    $services

    Write-Host "[!] - Voici tous les services $env:os qui ont le statut : $status" -ForegroundColor $color
    $continue = Read-Host "[?] - Voulez vous consulter un service spécifique [O] " 
    if ($continue -eq 'O' -or $continue -eq 'o') {

        do {
        
            $selectedService = Read-Host '[#] - Entrez le nom du service ' 
            $selected = Get-Service $selectedService -ErrorAction SilentlyContinue
            
            if($null -eq $selected){
                Write-Host "[-] - Service $selected inexistant, veuillez réessayer" -ForegroundColor Red
            }

        } while ($null -eq $selected)

        Get-Service $selectedService
    }

}
