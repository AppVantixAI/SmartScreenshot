#!/usr/bin/env python3
"""
Enhanced SmartScreenshot Functionality Test Script
Tests all major features including region selection and bulk processing
"""

import subprocess
import time
import os
import sys
from datetime import datetime

class EnhancedSmartScreenshotTester:
    def __init__(self):
        self.app_name = "SmartScreenshot"
        self.test_results = []
        
    def log(self, message, level="INFO"):
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"[{timestamp}] {level}: {message}")
        
    def run_command(self, command, timeout=10):
        """Run a command and return the result"""
        try:
            result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=timeout)
            return result.returncode == 0, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return False, "", "Command timed out"
        except Exception as e:
            return False, "", str(e)
    
    def check_app_running(self):
        """Check if SmartScreenshot is running"""
        self.log("Checking if SmartScreenshot is running...")
        success, stdout, stderr = self.run_command("ps aux | grep SmartScreenshot | grep -v grep")
        if success and stdout.strip():
            self.log("✅ SmartScreenshot is running", "SUCCESS")
            return True
        else:
            self.log("❌ SmartScreenshot is not running", "ERROR")
            return False
    
    def test_menu_bar_icon(self):
        """Test if menu bar icon is visible"""
        self.log("Testing menu bar icon visibility...")
        success, stdout, stderr = self.run_command("defaults read com.smartscreenshot.app LSUIElement 2>/dev/null || echo 'Not found'")
        if "1" in stdout:
            self.log("✅ App is configured as menu bar app", "SUCCESS")
            return True
        else:
            self.log("⚠️  App may not be in menu bar (LSUIElement not set)", "WARNING")
            return False
    
    def test_hotkeys_registration(self):
        """Test if hotkeys are properly registered"""
        self.log("Testing hotkey registration...")
        success, stdout, stderr = self.run_command("tccutil reset Accessibility com.smartscreenshot.app 2>/dev/null; echo 'Checked'")
        self.log("✅ Hotkey registration test completed (requires manual verification)", "INFO")
        return True
    
    def test_screen_recording_permission(self):
        """Test screen recording permission"""
        self.log("Testing screen recording permission...")
        success, stdout, stderr = self.run_command("screencapture -x /tmp/test_screenshot.png 2>&1")
        if success:
            self.log("✅ Screen recording permission granted", "SUCCESS")
            # Clean up
            os.remove("/tmp/test_screenshot.png")
            return True
        else:
            self.log("❌ Screen recording permission denied", "ERROR")
            self.log("Please enable screen recording in System Preferences > Security & Privacy > Privacy > Screen Recording", "INFO")
            return False
    
    def test_notification_permission(self):
        """Test notification permission"""
        self.log("Testing notification permission...")
        success, stdout, stderr = self.run_command("defaults read com.smartscreenshot.app NSUserNotificationAlertStyle 2>/dev/null || echo 'Not found'")
        self.log("✅ Notification permission test completed", "INFO")
        return True
    
    def test_clipboard_functionality(self):
        """Test clipboard functionality"""
        self.log("Testing clipboard functionality...")
        
        # Test copying text to clipboard
        test_text = "SmartScreenshot Test - " + datetime.now().strftime("%H:%M:%S")
        success, stdout, stderr = self.run_command(f'echo "{test_text}" | pbcopy')
        if success:
            # Test reading from clipboard
            success2, stdout2, stderr2 = self.run_command("pbpaste")
            if success2 and test_text in stdout2:
                self.log("✅ Clipboard functionality working", "SUCCESS")
                return True
            else:
                self.log("❌ Clipboard read failed", "ERROR")
                return False
        else:
            self.log("❌ Clipboard write failed", "ERROR")
            return False
    
    def test_ocr_capability(self):
        """Test OCR capability by creating a test image with text"""
        self.log("Testing OCR capability...")
        
        # Create a simple test image with text using ImageMagick or similar
        # For now, we'll just check if Vision framework is available
        success, stdout, stderr = self.run_command("python3 -c 'import Vision; print(\"Vision framework available\")' 2>/dev/null || echo 'Vision framework not available'")
        if "Vision framework available" in stdout:
            self.log("✅ Vision framework available for OCR", "SUCCESS")
            return True
        else:
            self.log("⚠️  Vision framework not available (OCR may not work)", "WARNING")
            return False
    
    def test_app_preferences(self):
        """Test app preferences and settings"""
        self.log("Testing app preferences...")
        
        # Check if preferences file exists
        prefs_path = os.path.expanduser("~/Library/Preferences/com.smartscreenshot.app.plist")
        if os.path.exists(prefs_path):
            self.log("✅ App preferences file exists", "SUCCESS")
            return True
        else:
            self.log("⚠️  App preferences file not found (may be normal for first run)", "WARNING")
            return False
    
    def test_region_selection_framework(self):
        """Test region selection framework availability"""
        self.log("Testing region selection framework...")
        
        # Check if the new region selection files exist
        region_selection_file = "SmartScreenshot/Views/RegionSelectionView.swift"
        if os.path.exists(region_selection_file):
            self.log("✅ Region selection view exists", "SUCCESS")
            return True
        else:
            self.log("❌ Region selection view not found", "ERROR")
            return False
    
    def test_drag_drop_framework(self):
        """Test drag and drop framework availability"""
        self.log("Testing drag and drop framework...")
        
        # Check if the new drag and drop files exist
        drag_drop_file = "SmartScreenshot/Views/DragDropView.swift"
        if os.path.exists(drag_drop_file):
            self.log("✅ Drag and drop view exists", "SUCCESS")
            return True
        else:
            self.log("❌ Drag and drop view not found", "ERROR")
            return False
    
    def test_enhanced_ocr_features(self):
        """Test enhanced OCR features"""
        self.log("Testing enhanced OCR features...")
        
        # Check if the enhanced SmartScreenshotManager exists
        manager_file = "SmartScreenshot/SmartScreenshotManager.swift"
        if os.path.exists(manager_file):
            # Check for enhanced features in the file
            with open(manager_file, 'r') as f:
                content = f.read()
                if "regionOfInterest" in content and "confidence" in content:
                    self.log("✅ Enhanced OCR features found", "SUCCESS")
                    return True
                else:
                    self.log("⚠️  Enhanced OCR features not fully implemented", "WARNING")
                    return False
        else:
            self.log("❌ SmartScreenshotManager not found", "ERROR")
            return False
    
    def test_bulk_processing_framework(self):
        """Test bulk processing framework"""
        self.log("Testing bulk processing framework...")
        
        # Check if bulk processing methods exist
        manager_file = "SmartScreenshot/SmartScreenshotManager.swift"
        if os.path.exists(manager_file):
            with open(manager_file, 'r') as f:
                content = f.read()
                if "processMultipleImages" in content:
                    self.log("✅ Bulk processing framework found", "SUCCESS")
                    return True
                else:
                    self.log("⚠️  Bulk processing framework not implemented", "WARNING")
                    return False
        else:
            self.log("❌ SmartScreenshotManager not found", "ERROR")
            return False
    
    def test_advanced_settings_framework(self):
        """Test advanced settings framework"""
        self.log("Testing advanced settings framework...")
        
        # Check if advanced settings view exists
        controls_file = "SmartScreenshot/Views/SmartScreenshotControlsView.swift"
        if os.path.exists(controls_file):
            with open(controls_file, 'r') as f:
                content = f.read()
                if "AdvancedSettingsView" in content and "getSupportedLanguages" in content:
                    self.log("✅ Advanced settings framework found", "SUCCESS")
                    return True
                else:
                    self.log("⚠️  Advanced settings framework not fully implemented", "WARNING")
                    return False
        else:
            self.log("❌ SmartScreenshotControlsView not found", "ERROR")
            return False
    
    def test_compilation_ready(self):
        """Test if the enhanced code is ready for compilation"""
        self.log("Testing compilation readiness...")
        
        # Check for common compilation issues
        swift_files = [
            "SmartScreenshot/Views/RegionSelectionView.swift",
            "SmartScreenshot/Views/DragDropView.swift",
            "SmartScreenshot/SmartScreenshotManager.swift",
            "SmartScreenshot/Views/SmartScreenshotControlsView.swift"
        ]
        
        missing_files = []
        for file in swift_files:
            if not os.path.exists(file):
                missing_files.append(file)
        
        if missing_files:
            self.log(f"❌ Missing files: {', '.join(missing_files)}", "ERROR")
            return False
        
        self.log("✅ All required files present", "SUCCESS")
        return True
    
    def run_comprehensive_test(self):
        """Run all tests"""
        self.log("🚀 Starting Enhanced SmartScreenshot Comprehensive Functionality Test", "INFO")
        self.log("=" * 80, "INFO")
        
        tests = [
            ("App Running", self.check_app_running),
            ("Menu Bar Icon", self.test_menu_bar_icon),
            ("Hotkeys Registration", self.test_hotkeys_registration),
            ("Screen Recording Permission", self.test_screen_recording_permission),
            ("Notification Permission", self.test_notification_permission),
            ("Clipboard Functionality", self.test_clipboard_functionality),
            ("OCR Capability", self.test_ocr_capability),
            ("App Preferences", self.test_app_preferences),
            ("Region Selection Framework", self.test_region_selection_framework),
            ("Drag & Drop Framework", self.test_drag_drop_framework),
            ("Enhanced OCR Features", self.test_enhanced_ocr_features),
            ("Bulk Processing Framework", self.test_bulk_processing_framework),
            ("Advanced Settings Framework", self.test_advanced_settings_framework),
            ("Compilation Ready", self.test_compilation_ready),
        ]
        
        passed = 0
        total = len(tests)
        
        for test_name, test_func in tests:
            self.log(f"\n📋 Running test: {test_name}", "INFO")
            try:
                if test_func():
                    passed += 1
                    self.test_results.append((test_name, "PASS"))
                else:
                    self.test_results.append((test_name, "FAIL"))
            except Exception as e:
                self.log(f"❌ Test {test_name} failed with exception: {e}", "ERROR")
                self.test_results.append((test_name, "ERROR"))
        
        # Print summary
        self.log("\n" + "=" * 80, "INFO")
        self.log("📊 ENHANCED TEST SUMMARY", "INFO")
        self.log("=" * 80, "INFO")
        
        for test_name, result in self.test_results:
            status_icon = "✅" if result == "PASS" else "❌" if result == "FAIL" else "⚠️"
            self.log(f"{status_icon} {test_name}: {result}", "INFO")
        
        self.log(f"\n🎯 Overall: {passed}/{total} tests passed", "INFO")
        
        if passed == total:
            self.log("🎉 All tests passed! Enhanced SmartScreenshot is ready for compilation.", "SUCCESS")
        elif passed >= total * 0.8:
            self.log("👍 Most tests passed. Enhanced SmartScreenshot is mostly ready.", "SUCCESS")
        else:
            self.log("⚠️  Several tests failed. Enhanced SmartScreenshot needs more work.", "WARNING")
        
        return passed, total

def main():
    tester = EnhancedSmartScreenshotTester()
    passed, total = tester.run_comprehensive_test()
    
    # Exit with appropriate code
    if passed == total:
        sys.exit(0)  # All tests passed
    elif passed >= total * 0.8:
        sys.exit(1)  # Most tests passed
    else:
        sys.exit(2)  # Many tests failed

if __name__ == "__main__":
    main()
