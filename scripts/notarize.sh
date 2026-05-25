#!/bin/bash
set -e

# ImgurUnblocker Safari Notarization Script
#
# Prerequisites:
#   1. Developer ID Application certificate installed
#   2. Keychain profile created via:
#      xcrun notarytool store-credentials "notarytool-password" \
#        --apple-id "your-email@example.com" \
#        --team-id "Q3Z639YB49" \
#        --password "xxxx-xxxx-xxxx-xxxx"

# Configuration
PROJECT_NAME="ImgurUnblocker"
APP_NAME="ImgurUnblocker"
SCHEME="ImgurUnblocker"
CONFIGURATION="Release"
KEYCHAIN_PROFILE="notarytool-password"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
XCODE_DIR="$REPO_DIR/ImgurUnblocker"
BUILD_DIR="$REPO_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/$PROJECT_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
APP_PATH="$EXPORT_PATH/$APP_NAME.app"
ZIP_PATH="$BUILD_DIR/$APP_NAME.zip"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step()    { echo -e "\n${GREEN}▶ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error()   { echo -e "${RED}✖ $1${NC}"; }
print_success() { echo -e "${GREEN}✔ $1${NC}"; }

check_prerequisites() {
    print_step "Checking prerequisites..."

    if ! command -v xcodebuild &> /dev/null; then
        print_error "xcodebuild not found. Install Xcode Command Line Tools."
        exit 1
    fi

    if ! xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" &> /dev/null; then
        print_error "Keychain profile '$KEYCHAIN_PROFILE' not found."
        echo "Create it with:"
        echo "  xcrun notarytool store-credentials \"$KEYCHAIN_PROFILE\" \\"
        echo "    --apple-id \"your-email@example.com\" \\"
        echo "    --team-id \"Q3Z639YB49\" \\"
        echo "    --password \"xxxx-xxxx-xxxx-xxxx\""
        exit 1
    fi

    if [[ ! -f "$REPO_DIR/ExportOptions.plist" ]]; then
        print_error "ExportOptions.plist not found in repo root."
        exit 1
    fi

    print_success "Prerequisites OK"
}

clean_build() {
    print_step "Cleaning previous build..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    print_success "Clean complete"
}

archive_app() {
    print_step "Archiving app..."

    xcodebuild -project "$XCODE_DIR/$PROJECT_NAME.xcodeproj" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -archivePath "$ARCHIVE_PATH" \
        archive \
        | grep -E "^(Archive|error:|warning:|\*\*)" || true

    if [[ ! -d "$ARCHIVE_PATH" ]]; then
        print_error "Archive failed"
        exit 1
    fi

    print_success "Archive complete: $ARCHIVE_PATH"
}

export_app() {
    print_step "Exporting app with Developer ID signing..."

    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$REPO_DIR/ExportOptions.plist" \
        | grep -E "^(Export|error:|warning:|\*\*)" || true

    if [[ ! -d "$APP_PATH" ]]; then
        print_error "Export failed"
        exit 1
    fi

    print_success "Export complete: $APP_PATH"
}

create_zip() {
    print_step "Creating ZIP for notarization..."
    ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
    print_success "ZIP created: $ZIP_PATH"
}

notarize_app() {
    print_step "Submitting for notarization (this may take a few minutes)..."
    xcrun notarytool submit "$ZIP_PATH" \
        --keychain-profile "$KEYCHAIN_PROFILE" \
        --wait
    print_success "Notarization complete"
}

staple_app() {
    print_step "Stapling notarization ticket..."
    xcrun stapler staple "$APP_PATH"
    print_success "Stapling complete"
}

create_dmg() {
    print_step "Creating DMG..."
    rm -f "$DMG_PATH"

    hdiutil create -volname "$APP_NAME" \
        -srcfolder "$APP_PATH" \
        -ov -format UDZO \
        "$DMG_PATH"

    print_success "DMG created: $DMG_PATH"

    print_step "Notarizing DMG..."
    xcrun notarytool submit "$DMG_PATH" \
        --keychain-profile "$KEYCHAIN_PROFILE" \
        --wait

    print_step "Stapling DMG..."
    xcrun stapler staple "$DMG_PATH"

    print_success "DMG notarized and stapled"
}

verify_build() {
    print_step "Verifying notarization..."

    echo "Checking app..."
    spctl -a -v "$APP_PATH" 2>&1 || true

    echo ""
    echo "Checking DMG..."
    spctl -a -t open --context context:primary-signature -v "$DMG_PATH" 2>&1 || true

    print_success "Verification complete"
}

main() {
    echo "========================================="
    echo "  $PROJECT_NAME Notarization Script"
    echo "========================================="

    cd "$REPO_DIR"

    check_prerequisites
    clean_build
    archive_app
    export_app
    create_zip
    notarize_app
    staple_app
    create_dmg
    verify_build

    echo ""
    echo "========================================="
    print_success "Build complete!"
    echo "========================================="
    echo ""
    echo "Distributable files:"
    echo "  App: $APP_PATH"
    echo "  DMG: $DMG_PATH"
    echo ""
}

main "$@"
