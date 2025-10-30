#!/bin/bash
#
# Fix line endings for all deployment scripts
#
# This converts Windows line endings (CRLF) to Unix line endings (LF)
#

echo "Fixing line endings for deployment scripts..."

# Method 1: Using sed (works on all systems)
for file in diagnose.sh fix-connectivity.sh deploy.sh uninstall.sh; do
    if [ -f "$file" ]; then
        echo "Fixing $file..."
        sed -i 's/\r$//' "$file"
    fi
done

# Make scripts executable
chmod +x diagnose.sh fix-connectivity.sh deploy.sh uninstall.sh 2>/dev/null

echo "Done! Line endings fixed."
echo ""
echo "You can now run:"
echo "  sudo bash diagnose.sh"
echo "  sudo bash fix-connectivity.sh"
