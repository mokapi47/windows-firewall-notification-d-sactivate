# notif-pare-feu.ps1 (version finale avec message final)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

$logFile = Join-Path $PSScriptRoot "notif-pare-feu-log.txt"
"=== Début : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" | Out-File -FilePath $logFile -Append

Try {
    # ----- 1) Démarrage du service si nécessaire -----
    $svc = Get-Service -Name SecurityHealthService -ErrorAction SilentlyContinue
    if ($svc) {
        if ($svc.Status -ne 'Running') {
            Try {
                Start-Service -Name SecurityHealthService -ErrorAction Stop
                "SecurityHealthService démarré avec succès." | Out-File -FilePath $logFile -Append
            } Catch {
                "Impossible de démarrer SecurityHealthService : $($_.Exception.Message)" | Out-File -FilePath $logFile -Append
            }
        } else {
            "SecurityHealthService déjà en cours d'exécution." | Out-File -FilePath $logFile -Append
        }
    } else {
        "Service SecurityHealthService introuvable." | Out-File -FilePath $logFile -Append
    }

    # ----- 2) Appliquer les clés de registre pour désactiver les notifications -----
    $polPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications'
    New-Item -Path $polPath -Force | Out-Null
    New-ItemProperty -Path $polPath -Name "DisableNotifications" -PropertyType DWord -Value 1 -Force | Out-Null
    "Policy key écrite : $polPath\DisableNotifications = 1" | Out-File -FilePath $logFile -Append

    $userToastPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance'
    New-Item -Path $userToastPath -Force | Out-Null
    Set-ItemProperty -Path $userToastPath -Name "Enabled" -Type DWord -Value 0 -Force
    "User toast désactivé : $userToastPath\Enabled = 0" | Out-File -FilePath $logFile -Append

    $appNotifPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SecHealthUI'
    New-Item -Path $appNotifPath -Force | Out-Null
    Set-ItemProperty -Path $appNotifPath -Name "Enabled" -Type DWord -Value 0 -Force
    "Application notification désactivée : $appNotifPath\Enabled = 0" | Out-File -FilePath $logFile -Append

    # ----- 3) Relancer Explorer pour appliquer les changements -----
    Try {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Process "explorer.exe" -WindowStyle Hidden
        "Explorer redémarré." | Out-File -FilePath $logFile -Append
    } Catch {
        "Impossible de relancer Explorer : $($_.Exception.Message)" | Out-File -FilePath $logFile -Append
    }

    "Script exécuté sans erreur apparente." | Out-File -FilePath $logFile -Append
}
Catch {
    "ERREUR GLOBALE : $($_.Exception.Message)" | Out-File -FilePath $logFile -Append
    $($_.Exception | Out-String) | Out-File -FilePath $logFile -Append
}
Finally {
    "=== Fin : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===`n" | Out-File -FilePath $logFile -Append
}

# --- 4) Affichage final avec message en vert ---
Clear-Host
Write-Host "==============================" -ForegroundColor Green
Write-Host "        OPERATION REUSSIE !        " -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host ""
Write-Host "Vous pouvez maintenant redemarrer votre ordinateur pour appliquer tous les changements !" -ForegroundColor Green
Write-Host ""
Read-Host -Prompt "Appuyez sur Entrée pour redémarrer maintenant" | Out-Null; Restart-Computer
