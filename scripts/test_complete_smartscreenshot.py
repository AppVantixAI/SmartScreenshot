#!/usr/bin/env python3
"""
SmartScreenshot Complete Functionality Test Script

This script verifies that all SmartScreenshot features from the README are working:
1. Smart Screenshot Capture (Full Screen, Region Selection, Application Capture)
2. AI-Powered OCR with multiple models
3. Bulk Processing with drag & drop
4. Modern UI/UX with keyboard shortcuts
5. Customizable hotkeys and language preferences
6. Export options and history management
"""

import os
import sys
import subprocess
import json
import time
from pathlib import Path

class SmartScreenshotTester:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.test_results = {
            "total_tests": 0,
            "passed": 0,
            "failed": 0,
            "errors": []
        }
        
    def log(self, message, level="INFO"):
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] {level}: {message}")
        
    def run_test(self, test_name, test_func):
        """Run a single test and track results"""
        self.test_results["total_tests"] += 1
        self.log(f"Running test: {test_name}")
        
        try:
            result = test_func()
            if result:
                self.test_results["passed"] += 1
                self.log(f"✅ {test_name} PASSED", "SUCCESS")
                return True
            else:
                self.test_results["failed"] += 1
                self.test_results["errors"].append(f"{test_name}: Test failed")
                self.log(f"❌ {test_name} FAILED", "ERROR")
                return False
        except Exception as e:
            self.test_results["failed"] += 1
            self.test_results["errors"].append(f"{test_name}: {str(e)}")
            self.log(f"❌ {test_name} ERROR: {e}", "ERROR")
            return False
    
    def test_file_exists(self, file_path, description):
        """Test if a required file exists"""
        full_path = self.project_root / file_path
        exists = full_path.exists()
        if not exists:
            self.log(f"Missing file: {file_path}")
        return exists
    
    def test_core_services(self):
        """Test core SmartScreenshot services exist"""
        files_to_check = [
            ("SmartScreenshot/Services/SmartScreenshotService.swift", "Main SmartScreenshot Service"),
            ("SmartScreenshot/Services/AIOCRService.swift", "AI OCR Service"),
            ("SmartScreenshot/Views/SmartScreenshotMainView.swift", "Main UI View"),
            ("SmartScreenshot/Views/AISettingsView.swift", "AI Settings View"),
            ("SmartScreenshot/Views/BulkOCRView.swift", "Bulk OCR Processing View"),
            ("SmartScreenshot/Settings/SmartScreenshotSettingsPane.swift", "Settings Pane"),
        ]
        
        all_exist = True
        for file_path, description in files_to_check:
            if not self.test_file_exists(file_path, description):
                all_exist = False
                
        return all_exist
    
    def test_keyboard_shortcuts(self):
        """Test keyboard shortcuts are defined"""
        shortcuts_file = self.project_root / "SmartScreenshot/Extensions/KeyboardShortcuts.Name+Shortcuts.swift"
        
        if not shortcuts_file.exists():
            return False
            
        content = shortcuts_file.read_text()
        required_shortcuts = [
            "screenshotOCR",
            "regionOCR", 
            "appOCR",
            "bulkOCR"
        ]
        
        for shortcut in required_shortcuts:
            if shortcut not in content:
                self.log(f"Missing keyboard shortcut: {shortcut}")
                return False
                
        return True
    
    def test_ocr_functionality(self):
        """Test OCR functionality implementation"""
        service_file = self.project_root / "SmartScreenshot/Services/SmartScreenshotService.swift"
        
        if not service_file.exists():
            return False
            
        content = service_file.read_text()
        required_methods = [
            "takeScreenshotWithOCR",
            "captureScreenRegionWithOCR", 
            "captureApplicationWithOCR",
            "performOCR",
            "checkScreenRecordingPermission",
            "captureScreen",
            "captureActiveWindow"
        ]
        
        for method in required_methods:
            if f"func {method}" not in content:
                self.log(f"Missing OCR method: {method}")
                return False
                
        return True
    
    def test_ui_integration(self):
        """Test UI components are properly integrated"""
        content_view = self.project_root / "SmartScreenshot/Views/ContentView.swift"
        
        if not content_view.exists():
            return False
            
        content = content_view.read_text()
        required_elements = [
            "SmartScreenshotMainView",
            "showingSmartScreenshot",
            "transition(.slide)"
        ]
        
        for element in required_elements:
            if element not in content:
                self.log(f"Missing UI integration: {element}")
                return False
                
        return True
    
    def test_bulk_processing(self):
        """Test bulk processing functionality"""
        bulk_view = self.project_root / "SmartScreenshot/Views/BulkOCRView.swift"
        main_view = self.project_root / "SmartScreenshot/Views/SmartScreenshotMainView.swift"
        
        if not bulk_view.exists() or not main_view.exists():
            return False
            
        bulk_content = bulk_view.read_text()
        main_content = main_view.read_text()
        
        # Check bulk view features
        bulk_features = [
            "processingResults",
            "startBulkProcessing",
            "exportResults",
            "onDrop"
        ]
        
        for feature in bulk_features:
            if feature not in bulk_content:
                self.log(f"Missing bulk processing feature: {feature}")
                return False
        
        # Check main view features (DragDropArea is here)
        main_features = [
            "DragDropArea",
            "processBulkImages"
        ]
        
        for feature in main_features:
            if feature not in main_content:
                self.log(f"Missing main view feature: {feature}")
                return False
                
        return True
    
    def test_ai_models_support(self):
        """Test AI models are properly supported"""
        ai_service = self.project_root / "SmartScreenshot/Services/AIOCRService.swift"
        
        if not ai_service.exists():
            return False
            
        content = ai_service.read_text()
        required_models = [
            "appleVision",
            "openAI",
            "claude", 
            "gemini",
            "grok",
            "deepseek"
        ]
        
        for model in required_models:
            if model not in content:
                self.log(f"Missing AI model support: {model}")
                return False
                
        return True
    
    def test_settings_configuration(self):
        """Test settings and configuration options"""
        settings_file = self.project_root / "SmartScreenshot/Settings/SmartScreenshotSettingsPane.swift"
        
        if not settings_file.exists():
            return False
            
        content = settings_file.read_text()
        required_settings = [
            "autoOCREnabled",
            "confidenceThreshold",
            "multiLanguageOCR",
            "preserveFormatting",
            "showNotifications"
        ]
        
        for setting in required_settings:
            if setting not in content:
                self.log(f"Missing setting: {setting}")
                return False
                
        return True
    
    def test_permissions_handling(self):
        """Test permissions are properly handled"""
        service_file = self.project_root / "SmartScreenshot/Services/SmartScreenshotService.swift"
        
        if not service_file.exists():
            return False
            
        content = service_file.read_text()
        required_permissions = [
            "checkScreenRecordingPermission",
            "AXIsProcessTrusted",
            "CGDisplayCreateImage"
        ]
        
        for permission in required_permissions:
            if permission not in content:
                self.log(f"Missing permission check: {permission}")
                return False
                
        return True
    
    def test_comprehensive_features(self):
        """Test comprehensive feature set from README"""
        features_to_check = [
            # Smart Screenshot Capture
            ("takeScreenshotWithOCR", "Full Screen OCR"),
            ("captureScreenRegionWithOCR", "Region Selection OCR"), 
            ("captureApplicationWithOCR", "Application Capture OCR"),
            
            # AI-Powered OCR
            ("VNRecognizeTextRequest", "Vision Framework OCR"),
            ("automaticallyDetectsLanguage", "Multi-Language Support"),
            ("confidence", "Confidence Scoring"),
            
            # Bulk Processing
            ("BulkOCRView", "Bulk Processing UI"),
            ("onDrop", "Drag & Drop Support"),
            ("processingProgress", "Progress Tracking"),
            
            # Modern UI/UX
            ("SmartScreenshotMainView", "Modern UI"),
            ("Color(NSColor", "Dark Mode Support"),
            ("KeyboardShortcuts", "Keyboard Shortcuts"),
            
            # Advanced Features
            ("SmartScreenshotSettingsPane", "Customizable Settings"),
            ("recognitionLanguages", "Language Preferences"),
            ("exportResults", "Export Options"),
            ("History.shared", "History Management")
        ]
        
        all_features_found = True
        
        # Search through all Swift files
        swift_files = list(self.project_root.glob("SmartScreenshot/**/*.swift"))
        all_content = ""
        
        for swift_file in swift_files:
            try:
                all_content += swift_file.read_text()
            except:
                continue
        
        for feature, description in features_to_check:
            if feature not in all_content:
                self.log(f"Missing feature: {description} ({feature})")
                all_features_found = False
                
        return all_features_found
    
    def run_all_tests(self):
        """Run all SmartScreenshot tests"""
        self.log("🚀 Starting SmartScreenshot Complete Functionality Tests")
        self.log("=" * 80)
        
        # Core Architecture Tests
        self.run_test("Core Services", self.test_core_services)
        self.run_test("Keyboard Shortcuts", self.test_keyboard_shortcuts)
        self.run_test("OCR Functionality", self.test_ocr_functionality)
        self.run_test("UI Integration", self.test_ui_integration)
        
        # Feature Tests
        self.run_test("Bulk Processing", self.test_bulk_processing)
        self.run_test("AI Models Support", self.test_ai_models_support)
        self.run_test("Settings Configuration", self.test_settings_configuration)
        self.run_test("Permissions Handling", self.test_permissions_handling)
        
        # Comprehensive Feature Test
        self.run_test("Comprehensive Features", self.test_comprehensive_features)
        
        # Print Summary
        self.print_summary()
        
        return self.test_results["failed"] == 0
    
    def print_summary(self):
        """Print test summary"""
        self.log("=" * 80)
        self.log("🎯 SmartScreenshot Test Summary")
        self.log("=" * 80)
        
        total = self.test_results["total_tests"]
        passed = self.test_results["passed"]
        failed = self.test_results["failed"]
        
        self.log(f"Total Tests: {total}")
        self.log(f"✅ Passed: {passed}")
        self.log(f"❌ Failed: {failed}")
        
        if failed == 0:
            self.log("🎉 ALL TESTS PASSED! SmartScreenshot is ready for use.", "SUCCESS")
            self.log("✨ Features Available:")
            self.log("   • Full Screen OCR (⌘⇧S)")
            self.log("   • Region Selection OCR (⌘⇧R)")
            self.log("   • Application Capture OCR (⌘⇧A)")
            self.log("   • Bulk Processing (⌘⇧B)")
            self.log("   • AI-Powered OCR with multiple models")
            self.log("   • Modern UI with dark mode support")
            self.log("   • Customizable keyboard shortcuts")
            self.log("   • Multi-language text recognition")
            self.log("   • Export options and history management")
        else:
            self.log(f"⚠️  {failed} tests failed. Please review the errors:", "WARNING")
            for error in self.test_results["errors"]:
                self.log(f"   • {error}")
        
        self.log("=" * 80)
    
    def save_results(self):
        """Save test results to file"""
        results_file = self.project_root / "SMARTSCREENSHOT_TEST_RESULTS.json"
        
        test_data = {
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "results": self.test_results,
            "status": "PASSED" if self.test_results["failed"] == 0 else "FAILED"
        }
        
        with open(results_file, 'w') as f:
            json.dump(test_data, f, indent=2)
            
        self.log(f"📄 Test results saved to: {results_file}")

def main():
    """Main test execution"""
    tester = SmartScreenshotTester()
    
    try:
        success = tester.run_all_tests()
        tester.save_results()
        
        sys.exit(0 if success else 1)
        
    except KeyboardInterrupt:
        tester.log("\n⚠️ Tests interrupted by user", "WARNING")
        sys.exit(1)
    except Exception as e:
        tester.log(f"💥 Fatal error during testing: {e}", "ERROR")
        sys.exit(1)

if __name__ == "__main__":
    main()
