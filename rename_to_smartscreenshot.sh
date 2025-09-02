#!/bin/bash

# SmartScreenshot Project Renaming Script
# This script helps rename the project from Maccy to SmartScreenshot

echo "🚀 Starting SmartScreenshot Project Renaming Process..."
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "Maccy.xcodeproj/project.pbxproj" ]; then
    print_error "This script must be run from the project root directory"
    exit 1
fi

print_info "Current directory: $(pwd)"
print_info "Found Maccy.xcodeproj - proceeding with renaming..."

# Create backup
print_info "Creating backup of current project..."
BACKUP_DIR="Maccy_Backup_$(date +%Y%m%d_%H%M%S)"
cp -r . "../$BACKUP_DIR"
print_status "Backup created at: ../$BACKUP_DIR"

# Step 1: Rename main project files
print_info "Step 1: Renaming main project files..."

if [ -f "Maccy.xcodeproj" ]; then
    mv "Maccy.xcodeproj" "SmartScreenshot.xcodeproj"
    print_status "Renamed Maccy.xcodeproj → SmartScreenshot.xcodeproj"
fi

if [ -f "Maccy.xctestplan" ]; then
    mv "Maccy.xctestplan" "SmartScreenshot.xctestplan"
    print_status "Renamed Maccy.xctestplan → SmartScreenshot.xctestplan"
fi

# Step 2: Rename test directories
print_info "Step 2: Renaming test directories..."

if [ -d "MaccyTests" ]; then
    mv "MaccyTests" "SmartScreenshotTests"
    print_status "Renamed MaccyTests → SmartScreenshotTests"
fi

if [ -d "MaccyUITests" ]; then
    mv "MaccyUITests" "SmartScreenshotUITests"
    print_status "Renamed MaccyUITests → SmartScreenshotUITests"
fi

# Step 3: Rename main source directory
print_info "Step 3: Renaming main source directory..."

if [ -d "Maccy" ]; then
    mv "Maccy" "SmartScreenshot"
    print_status "Renamed Maccy → SmartScreenshot"
fi

# Step 4: Update project.pbxproj file
print_info "Step 4: Updating project.pbxproj file..."

if [ -f "SmartScreenshot.xcodeproj/project.pbxproj" ]; then
    # Create a backup of the project file
    cp "SmartScreenshot.xcodeproj/project.pbxproj" "SmartScreenshot.xcodeproj/project.pbxproj.backup"
    
    # Replace Maccy references with SmartScreenshot
    sed -i '' 's/Maccy/SmartScreenshot/g' "SmartScreenshot.xcodeproj/project.pbxproj"
    sed -i '' 's/maccy/smartscreenshot/g' "SmartScreenshot.xcodeproj/project.pbxproj"
    
    print_status "Updated project.pbxproj file"
else
    print_error "Could not find project.pbxproj file"
fi

# Step 5: Update workspace file
print_info "Step 5: Updating workspace file..."

if [ -f "SmartScreenshot.xcodeproj/project.xcworkspace/contents.xcworkspacedata" ]; then
    sed -i '' 's/Maccy/SmartScreenshot/g' "SmartScreenshot.xcodeproj/project.xcworkspace/contents.xcworkspacedata"
    print_status "Updated workspace file"
fi

# Step 6: Update scheme file
print_info "Step 6: Updating scheme file..."

if [ -f "SmartScreenshot.xcodeproj/xcshareddata/xcschemes/Maccy.xcscheme" ]; then
    mv "SmartScreenshot.xcodeproj/xcshareddata/xcschemes/Maccy.xcscheme" "SmartScreenshot.xcodeproj/xcshareddata/xcschemes/SmartScreenshot.xcscheme"
    sed -i '' 's/Maccy/SmartScreenshot/g' "SmartScreenshot.xcodeproj/xcshareddata/xcschemes/SmartScreenshot.xcscheme"
    print_status "Updated scheme file"
fi

# Step 7: Update Info.plist files
print_info "Step 7: Updating Info.plist files..."

# Main app Info.plist
if [ -f "SmartScreenshot/Info.plist" ]; then
    sed -i '' 's/Maccy/SmartScreenshot/g' "SmartScreenshot/Info.plist"
    sed -i '' 's/org\.p0deje\.Maccy/com.smartscreenshot.app/g' "SmartScreenshot/Info.plist"
    print_status "Updated main Info.plist"
fi

# Test Info.plist files
if [ -f "SmartScreenshotTests/Info.plist" ]; then
    sed -i '' 's/Maccy/SmartScreenshot/g' "SmartScreenshotTests/Info.plist"
    sed -i '' 's/org\.p0deje\.Maccy/com.smartscreenshot.app/g' "SmartScreenshotTests/Info.plist"
    print_status "Updated test Info.plist"
fi

if [ -f "SmartScreenshotUITests/Info.plist" ]; then
    sed -i '' 's/Maccy/SmartScreenshot/g' "SmartScreenshotUITests/Info.plist"
    sed -i '' 's/org\.p0deje\.Maccy/com.smartscreenshot.app/g' "SmartScreenshotUITests/Info.plist"
    print_status "Updated UI test Info.plist"
fi

# Step 8: Update Swift files
print_info "Step 8: Updating Swift files..."

# Find all Swift files and update them
find . -name "*.swift" -type f | while read -r file; do
    if [ -f "$file" ]; then
        # Create backup
        cp "$file" "$file.backup"
        
        # Replace Maccy references
        sed -i '' 's/Maccy/SmartScreenshot/g' "$file"
        sed -i '' 's/maccy/smartscreenshot/g' "$file"
        
        print_status "Updated: $file"
    fi
done

# Step 9: Update other configuration files
print_info "Step 9: Updating configuration files..."

# Update .gitignore if it exists
if [ -f ".gitignore" ]; then
    sed -i '' 's/Maccy/SmartScreenshot/g' ".gitignore"
    print_status "Updated .gitignore"
fi

# Update .swiftlint.yml if it exists
if [ -f ".swiftlint.yml" ]; then
    sed -i '' 's/Maccy/SmartScreenshot/g' ".swiftlint.yml"
    print_status "Updated .swiftlint.yml"
fi

# Update .periphery.yml if it exists
if [ -f ".periphery.yml" ]; then
    sed -i '' 's/Maccy/SmartScreenshot/g' ".periphery.yml"
    print_status "Updated .periphery.yml"
fi

# Update .bartycrouch.toml if it exists
if [ -f ".bartycrouch.toml" ]; then
    sed -i '' 's/Maccy/SmartScreenshot/g' ".bartycrouch.toml"
    print_status "Updated .bartycrouch.toml"
fi

# Step 10: Update appcast.xml
print_info "Step 10: Updating appcast.xml..."

if [ -f "appcast.xml" ]; then
    sed -i '' 's/Maccy/SmartScreenshot/g' "appcast.xml"
    sed -i '' 's/maccy/smartscreenshot/g' "appcast.xml"
    print_status "Updated appcast.xml"
fi

# Step 11: Update Python test files
print_info "Step 11: Updating Python test files..."

if [ -f "test_smartscreenshot.py" ]; then
    sed -i '' 's/Maccy/SmartScreenshot/g' "test_smartscreenshot.py"
    print_status "Updated test_smartscreenshot.py"
fi

if [ -f "test_enhanced_smartscreenshot.py" ]; then
    sed -i '' 's/Maccy/SmartScreenshot/g' "test_enhanced_smartscreenshot.py"
    print_status "Updated test_enhanced_smartscreenshot.py"
fi

# Step 12: Update documentation files
print_info "Step 12: Updating documentation files..."

# Update all markdown files
find . -name "*.md" -type f | while read -r file; do
    if [ -f "$file" ]; then
        # Create backup
        cp "$file" "$file.backup"
        
        # Replace Maccy references
        sed -i '' 's/Maccy/SmartScreenshot/g' "$file"
        sed -i '' 's/maccy/smartscreenshot/g' "$file"
        
        print_status "Updated: $file"
    fi
done

# Step 13: Update directory structure references
print_info "Step 13: Updating directory structure references..."

# Update any hardcoded paths in Swift files
find . -name "*.swift" -type f | while read -r file; do
    if [ -f "$file" ]; then
        # Update import statements and file paths
        sed -i '' 's|Maccy/|SmartScreenshot/|g' "$file"
        print_status "Updated paths in: $file"
    fi
done

# Step 14: Final verification
print_info "Step 14: Final verification..."

echo ""
echo "🔍 Checking for remaining Maccy references..."
REMAINING_REFERENCES=$(grep -r "Maccy" . --exclude-dir=.git --exclude-dir=../$BACKUP_DIR 2>/dev/null | wc -l)

if [ "$REMAINING_REFERENCES" -eq 0 ]; then
    print_status "No remaining Maccy references found!"
else
    print_warning "Found $REMAINING_REFERENCES remaining Maccy references. These may need manual review:"
    grep -r "Maccy" . --exclude-dir=.git --exclude-dir=../$BACKUP_DIR 2>/dev/null | head -10
fi

# Step 15: Summary
echo ""
echo "🎉 SmartScreenshot Project Renaming Complete!"
echo "============================================="
echo ""
echo "📁 Files Renamed:"
echo "   • Maccy.xcodeproj → SmartScreenshot.xcodeproj"
echo "   • Maccy.xctestplan → SmartScreenshot.xctestplan"
echo "   • Maccy/ → SmartScreenshot/"
echo "   • MaccyTests/ → SmartScreenshotTests/"
echo "   • MaccyUITests/ → SmartScreenshotUITests/"
echo ""
echo "🔧 Files Updated:"
echo "   • project.pbxproj"
echo "   • Info.plist files"
echo "   • Swift source files"
echo "   • Configuration files"
echo "   • Documentation files"
echo ""
echo "💾 Backup Created:"
echo "   • Location: ../$BACKUP_DIR"
echo ""
echo "⚠️  Important Next Steps:"
echo "   1. Open SmartScreenshot.xcodeproj in Xcode"
echo "   2. Update bundle identifier in project settings"
echo "   3. Update app name and version"
echo "   4. Clean and rebuild the project"
echo "   5. Test all functionality"
echo ""
echo "🚀 Your SmartScreenshot project is ready!"

# Make the script executable
chmod +x rename_to_smartscreenshot.sh

print_status "Script completed successfully!"
