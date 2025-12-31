#!/bin/bash

# Power Management Settings for macOS
# This script applies power management settings based on the machine model

set -e

# Get current machine model
MODEL=$(system_profiler SPHardwareDataType | grep "Model Identifier" | awk '{print $3}')

echo "Detected model: $MODEL"

# Function to apply iMac 2020 settings
apply_imac2020_settings() {
    echo "Applying power management settings for iMac 2020..."

    # Wake on LAN - Allow wake from network
    sudo pmset -a womp 1

    # Auto restart after power failure
    sudo pmset -a autorestart 1

    # Sleep settings
    sudo pmset -a sleep 0                    # Never sleep automatically
    sudo pmset -a displaysleep 90            # Display sleep after 90 minutes
    sudo pmset -a disksleep 10               # Disk sleep after 10 minutes

    # Hibernate settings
    sudo pmset -a hibernatemode 3            # Hybrid sleep (RAM + disk)

    # Standby settings
    sudo pmset -a standby 1                  # Enable standby mode
    sudo pmset -a standbydelayhigh 86400     # Standby delay high (24 hours)
    sudo pmset -a standbydelaylow 86400      # Standby delay low (24 hours)
    sudo pmset -a highstandbythreshold 50    # Battery threshold for standby

    # Power button behavior
    sudo pmset -a Sleep\ On\ Power\ Button 1 # Sleep on power button press

    # Other settings
    sudo pmset -a ttyskeepawake 1            # Prevent sleep when remote session active
    sudo pmset -a powernap 1                 # Enable Power Nap
    sudo pmset -a proximitywake 1            # Wake for network access
    sudo pmset -a networkoversleep 0         # Don't maintain network during sleep
    sudo pmset -a tcpkeepalive 1             # Keep TCP connections alive
    sudo pmset -a halfdim 1                  # Dim display before sleep
    sudo pmset -a gpuswitch 2                # Automatic GPU switching

    # Scheduled auto power-on (for remote access during business trips)
    # Power on every day at 5:00 AM
    sudo pmset repeat poweron MTWRFSU 05:00:00

    echo "✓ Power management settings applied successfully"
    echo "  - Scheduled daily auto power-on at 5:00 AM"
}

# Function to apply MacBook settings (example for future use)
apply_macbook_settings() {
    echo "Applying power management settings for MacBook..."
    # Add MacBook-specific settings here if needed
    echo "⚠ MacBook settings not yet configured"
}

# Apply settings based on model
case "$MODEL" in
    iMac20,1)
        apply_imac2020_settings
        ;;
    MacBookPro*|MacBookAir*)
        apply_macbook_settings
        ;;
    *)
        echo "⚠ Unknown model: $MODEL"
        echo "Please configure settings manually or add model-specific settings to this script"
        exit 1
        ;;
esac

# Display current settings
echo ""
echo "Current power management settings:"
pmset -g custom
