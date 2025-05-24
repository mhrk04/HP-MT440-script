# Requires Administrator privileges to run successfully.
# This script configures both Computer and User Configuration policies for removable media access.

Write-Host "--- Configuring Computer Configuration Policies ---"

$computerPolicyRegistryKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices"
$computerPolicyValueName = "{53f5630d-b16b-11d2-b065-00104bd762ad}" # All Removable Storage Classes: Deny all access
$policyEnabled = "1" # '1' means Enabled (Deny access)

# Create the registry key if it doesn't exist for Computer Configuration
if (-not (Test-Path $computerPolicyRegistryKey)) {
    Write-Host "Creating Computer Configuration registry key: $computerPolicyRegistryKey"
    New-Item -Path $computerPolicyRegistryKey -Force | Out-Null
}

# Set the registry value to enable the Computer Configuration policy
Write-Host "Setting Computer Configuration policy 'All Removable Storage classes: Deny all access' to Enabled..."
try {
    Set-ItemProperty -Path $computerPolicyRegistryKey -Name $computerPolicyValueName -Value $policyEnabled -Force -ErrorAction Stop
    Write-Host "Computer Configuration policy set successfully."
}
catch {
    Write-Error "Failed to set Computer Configuration policy. Make sure you run this script with Administrator privileges."
    Write-Error $_.Exception.Message
    exit 1
}

Write-Host "`n--- Configuring User Configuration Policies ---"

# These policies reside under HKEY_CURRENT_USER (HKCU) when applied to a user.
# For all users, these would typically be in HKLM under a default profile,
# but directly setting them under HKCU for the currently logged-in user is common for local scripts.
# Note: For multiple users, consider how this policy will be applied to each user's profile.
# A startup script or logon script might be necessary in some scenarios.

$userPolicyRegistryBase = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices"

# Define the user-specific removable disk policies
$userPolicies = @{
    "Deny_Read"    = "{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}" # Removable Disks: Deny read access (for USBSTOR)
    "Deny_Write"   = "{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}" # Removable Disks: Deny write access (for USBSTOR)
    "Deny_Execute" = "{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}" # Removable Disks: Deny execute access (for USBSTOR)
}

# Create the base registry key if it doesn't exist for User Configuration
if (-not (Test-Path $userPolicyRegistryBase)) {
    Write-Host "Creating User Configuration base registry key: $userPolicyRegistryBase"
    New-Item -Path $userPolicyRegistryBase -Force | Out-Null
}

foreach ($policyName in $userPolicies.Keys) {
    $policyGUID = $userPolicies[$policyName]
    $policyKeyPath = "$userPolicyRegistryBase\$policyGUID"

    # Create the GUID-specific key if it doesn't exist
    if (-not (Test-Path $policyKeyPath)) {
        Write-Host "Creating User Configuration policy key: $policyKeyPath"
        New-Item -Path $policyKeyPath -Force | Out-Null
    }

    Write-Host "Setting User Configuration policy '$policyName' to Enabled (Deny access)..."
    try {
        Set-ItemProperty -Path $policyKeyPath -Name $policyName -Value $policyEnabled -Force -ErrorAction Stop
        Write-Host "User Configuration policy '$policyName' set successfully."
    }
    catch {
        Write-Error "Failed to set User Configuration policy '$policyName'. Error: $_.Exception.Message"
        # Continue even if one user policy fails, as Computer Config is primary
    }
}


# Step 3: Force a Group Policy update
Write-Host "`n--- Forcing Group Policy update ---"
Write-Host "This will apply policies for the current user and computer."
try {
    gpupdate /force
    Write-Host "Group Policy update initiated. The policies should now be applied."
}
catch {
    Write-Error "Failed to force Group Policy update. Error: $_.Exception.Message"
    exit 1
}

Write-Host "`nScript finished."
Write-Host "To verify, you can check the Local Group Policy Editor (gpedit.msc):"
Write-Host "1. Computer Configuration -> Administrative Templates -> System -> Removable Storage Access -> All Removable Storage classes: Deny all access (Should be 'Enabled')"
Write-Host "2. User Configuration -> Administrative Templates -> System -> Removable Storage Access (Check 'Deny read access', 'Deny write access', 'Deny execute access' - all should be 'Enabled')"
Write-Host "You can also try plugging in a USB drive to confirm access is denied."
