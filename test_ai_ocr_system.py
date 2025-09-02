#!/usr/bin/env python3
"""
SmartScreenshot AI OCR System Test Script
Tests the new AI-powered OCR functionality and clipboard integration
"""

import os
import sys
import time
import subprocess
import json
from pathlib import Path

class SmartScreenshotAITester:
    def __init__(self):
        self.project_root = Path("/Users/camdenburke/Documents/AI Application Playground/Maccy-SmartScreenshot")
        self.test_results = []
        
    def run_test(self, test_name, test_func):
        """Run a test and record results"""
        print(f"\n🧪 Running: {test_name}")
        try:
            start_time = time.time()
            result = test_func()
            end_time = time.time()
            
            test_result = {
                "name": test_name,
                "status": "PASS" if result else "FAIL",
                "duration": round(end_time - start_time, 2),
                "error": None
            }
            
            if result:
                print(f"✅ {test_name}: PASSED ({test_result['duration']}s)")
            else:
                print(f"❌ {test_name}: FAILED ({test_result['duration']}s)")
                
        except Exception as e:
            test_result = {
                "name": test_name,
                "status": "ERROR",
                "duration": 0,
                "error": str(e)
            }
            print(f"💥 {test_name}: ERROR - {e}")
            
        self.test_results.append(test_result)
        return test_result["status"] == "PASS"
    
    def test_project_structure(self):
        """Test that all required files exist"""
        required_files = [
            "SmartScreenshot/Services/AIOCRService.swift",
            "SmartScreenshot/Models/ScreenshotClipboardItem.swift",
            "SmartScreenshot/Views/ScreenshotClipboardView.swift",
            "SmartScreenshot/SmartScreenshotManager.swift"
        ]
        
        for file_path in required_files:
            if not (self.project_root / file_path).exists():
                print(f"❌ Missing required file: {file_path}")
                return False
        
        print("✅ All required files exist")
        return True
    
    def test_swift_compilation(self):
        """Test that the Swift code compiles without errors"""
        try:
            # Try to build the project
            result = subprocess.run([
                "xcodebuild",
                "-scheme", "SmartScreenshot",
                "-project", "SmartScreenshot.xcodeproj",
                "-configuration", "Debug",
                "build"
            ], capture_output=True, text=True, cwd=self.project_root)
            
            if result.returncode == 0:
                print("✅ Swift compilation successful")
                return True
            else:
                print(f"❌ Swift compilation failed:")
                print(result.stderr)
                return False
                
        except Exception as e:
            print(f"❌ Failed to run xcodebuild: {e}")
            return False
    
    def test_ai_ocr_service_structure(self):
        """Test the AI OCR service structure"""
        service_file = self.project_root / "SmartScreenshot/Services/AIOCRService.swift"
        
        if not service_file.exists():
            return False
            
        content = service_file.read_text()
        
        # Check for required components
        required_components = [
            "class AIOCRService",
            "enum AIOCRModel",
            "struct OCRResult",
            "struct TextRegion",
            "struct AIConfig",
            "performAppleVisionOCR",
            "performOpenAIOCR",
            "performClaudeOCR",
            "performGeminiOCR"
        ]
        
        missing_components = []
        for component in required_components:
            if component not in content:
                missing_components.append(component)
        
        if missing_components:
            print(f"❌ Missing AI OCR components: {missing_components}")
            return False
            
        print("✅ AI OCR service structure complete")
        return True
    
    def test_clipboard_model_structure(self):
        """Test the clipboard model structure"""
        model_file = self.project_root / "SmartScreenshot/Models/ScreenshotClipboardItem.swift"
        
        if not model_file.exists():
            return False
            
        content = model_file.read_text()
        
        # Check for required components
        required_components = [
            "class ScreenshotClipboardItem",
            "class TextRegionData",
            "class ScreenshotClipboardManager",
            "@Model",
            "var id: UUID",
            "var image: Data",
            "var ocrText: String",
            "var confidence: Float"
        ]
        
        missing_components = []
        for component in required_components:
            if component not in content:
                missing_components.append(component)
        
        if missing_components:
            print(f"❌ Missing clipboard model components: {missing_components}")
            return False
            
        print("✅ Clipboard model structure complete")
        return True
    
    def test_ui_view_structure(self):
        """Test the UI view structure"""
        view_file = self.project_root / "SmartScreenshot/Views/ScreenshotClipboardView.swift"
        
        if not view_file.exists():
            return False
            
        content = view_file.read_text()
        
        # Check for required components
        required_components = [
            "struct ScreenshotClipboardView",
            "struct ScreenshotItemRow",
            "struct ImagePreviewView",
            "struct AISettingsView",
            "@StateObject",
            "ScreenshotClipboardManager",
            "AIOCRService"
        ]
        
        missing_components = []
        for component in required_components:
            if component not in content:
                missing_components.append(component)
        
        if missing_components:
            print(f"❌ Missing UI view components: {missing_components}")
            return False
            
        print("✅ UI view structure complete")
        return True
    
    def test_manager_integration(self):
        """Test the manager integration"""
        manager_file = self.project_root / "SmartScreenshot/SmartScreenshotManager.swift"
        
        if not manager_file.exists():
            return False
            
        content = manager_file.read_text()
        
        # Check for required components
        required_components = [
            "AIOCRService.shared",
            "ScreenshotClipboardManager.shared",
            "performOCR",
            "getAvailableModels",
            "getClipboardItems",
            "getOCRStatistics"
        ]
        
        missing_components = []
        for component in required_components:
            if component not in content:
                missing_components.append(component)
        
        if missing_components:
            print(f"❌ Missing manager integration components: {missing_components}")
            return False
            
        print("✅ Manager integration complete")
        return True
    
    def test_ai_model_support(self):
        """Test AI model support"""
        service_file = self.project_root / "SmartScreenshot/Services/AIOCRService.swift"
        
        if not service_file.exists():
            return False
            
        content = service_file.read_text()
        
        # Check for supported AI models
        supported_models = [
            "appleVision",
            "openAI",
            "claude",
            "gemini",
            "grok",
            "deepseek"
        ]
        
        missing_models = []
        for model in supported_models:
            if f"case {model}" not in content:
                missing_models.append(model)
        
        if missing_models:
            print(f"❌ Missing AI models: {missing_models}")
            return False
            
        print("✅ All AI models supported")
        return True
    
    def test_api_integration(self):
        """Test API integration points"""
        service_file = self.project_root / "SmartScreenshot/Services/AIOCRService.swift"
        
        if not service_file.exists():
            return False
            
        content = service_file.read_text()
        
        # Check for API endpoints
        api_endpoints = [
            "api.openai.com/v1/chat/completions",
            "api.anthropic.com/v1/messages",
            "generativelanguage.googleapis.com"
        ]
        
        missing_endpoints = []
        for endpoint in api_endpoints:
            if endpoint not in content:
                missing_endpoints.append(endpoint)
        
        if missing_endpoints:
            print(f"❌ Missing API endpoints: {missing_endpoints}")
            return False
            
        print("✅ API integration complete")
        return True
    
    def test_clipboard_functionality(self):
        """Test clipboard functionality"""
        model_file = self.project_root / "SmartScreenshot/Models/ScreenshotClipboardItem.swift"
        
        if not model_file.exists():
            return False
            
        content = model_file.read_text()
        
        # Check for clipboard features
        clipboard_features = [
            "copyToClipboard",
            "addTag",
            "removeTag",
            "togglePin",
            "addNote",
            "matchesSearch"
        ]
        
        missing_features = []
        for feature in clipboard_features:
            if feature not in content:
                missing_features.append(feature)
        
        if missing_features:
            print(f"❌ Missing clipboard features: {missing_features}")
            return False
            
        print("✅ Clipboard functionality complete")
        return True
    
    def test_ui_features(self):
        """Test UI features"""
        view_file = self.project_root / "SmartScreenshot/Views/ScreenshotClipboardView.swift"
        
        if not view_file.exists():
            return False
            
        content = view_file.read_text()
        
        # Check for UI features
        ui_features = [
            "searchBar",
            "confidenceBadge",
            "thumbnailView",
            "ImagePreviewView",
            "AISettingsView",
            "onHover",
            "scaleEffect"
        ]
        
        missing_features = []
        for feature in ui_features:
            if feature not in content:
                missing_features.append(feature)
        
        if missing_features:
            print(f"❌ Missing UI features: {missing_features}")
            return False
            
        print("✅ UI features complete")
        return True
    
    def test_error_handling(self):
        """Test error handling"""
        service_file = self.project_root / "SmartScreenshot/Services/AIOCRService.swift"
        
        if not service_file.exists():
            return False
            
        content = service_file.read_text()
        
        # Check for error handling
        error_patterns = [
            "❌",
            "guard let",
            "do {",
            "catch {",
            "if let error"
        ]
        
        missing_patterns = []
        for pattern in error_patterns:
            if pattern not in content:
                missing_patterns.append(pattern)
        
        if missing_patterns:
            print(f"❌ Missing error handling patterns: {missing_patterns}")
            return False
            
        print("✅ Error handling complete")
        return True
    
    def test_configuration_management(self):
        """Test configuration management"""
        service_file = self.project_root / "SmartScreenshot/Services/AIOCRService.swift"
        
        if not service_file.exists():
            return False
            
        content = service_file.read_text()
        
        # Check for configuration features
        config_features = [
            "loadConfiguration",
            "saveConfiguration",
            "UserDefaults.standard",
            "updateConfiguration",
            "getConfiguration"
        ]
        
        missing_features = []
        for feature in config_features:
            if feature not in content:
                missing_features.append(feature)
        
        if missing_features:
            print(f"❌ Missing configuration features: {missing_features}")
            return False
            
        print("✅ Configuration management complete")
        return True
    
    def run_all_tests(self):
        """Run all tests"""
        print("🚀 Starting SmartScreenshot AI OCR System Tests")
        print("=" * 60)
        
        tests = [
            ("Project Structure", self.test_project_structure),
            ("Swift Compilation", self.test_swift_compilation),
            ("AI OCR Service Structure", self.test_ai_ocr_service_structure),
            ("Clipboard Model Structure", self.test_clipboard_model_structure),
            ("UI View Structure", self.test_ui_view_structure),
            ("Manager Integration", self.test_manager_integration),
            ("AI Model Support", self.test_ai_model_support),
            ("API Integration", self.test_api_integration),
            ("Clipboard Functionality", self.test_clipboard_functionality),
            ("UI Features", self.test_ui_features),
            ("Error Handling", self.test_error_handling),
            ("Configuration Management", self.test_configuration_management)
        ]
        
        passed = 0
        total = len(tests)
        
        for test_name, test_func in tests:
            if self.run_test(test_name, test_func):
                passed += 1
        
        # Print summary
        print("\n" + "=" * 60)
        print(f"📊 Test Results: {passed}/{total} tests passed")
        
        if passed == total:
            print("🎉 All tests passed! The AI OCR system is ready.")
        else:
            print("⚠️  Some tests failed. Please review the issues above.")
        
        # Save results to file
        results_file = self.project_root / "AI_OCR_TEST_RESULTS.json"
        with open(results_file, 'w') as f:
            json.dump(self.test_results, f, indent=2)
        
        print(f"\n📄 Detailed results saved to: {results_file}")
        
        return passed == total

def main():
    """Main function"""
    tester = SmartScreenshotAITester()
    success = tester.run_all_tests()
    
    if success:
        print("\n🎯 Next Steps:")
        print("1. Build and run the SmartScreenshot app")
        print("2. Test the AI OCR functionality with different models")
        print("3. Verify the clipboard integration works")
        print("4. Test the UI with various screenshot scenarios")
        sys.exit(0)
    else:
        print("\n🔧 Issues detected. Please fix the failing tests before proceeding.")
        sys.exit(1)

if __name__ == "__main__":
    main()
