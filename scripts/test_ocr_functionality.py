#!/usr/bin/env python3
"""
SmartScreenshot OCR Functionality Test
Creates a test image with text and verifies OCR capabilities
"""

import subprocess
import time
import os
import sys
from datetime import datetime

def create_test_image_with_text():
    """Create a test image with text using macOS tools"""
    
    # Create a simple test image with text using ImageMagick or similar
    # For now, we'll create a simple text file and convert it to an image
    
    test_text = "SmartScreenshot OCR Test - " + datetime.now().strftime("%H:%M:%S")
    
    # Create a simple HTML file with text
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{ 
                font-family: Arial, sans-serif; 
                font-size: 24px; 
                color: black; 
                background: white; 
                padding: 50px;
                margin: 0;
            }}
        </style>
    </head>
    <body>
        <h1>{test_text}</h1>
        <p>This is a test image for SmartScreenshot OCR functionality.</p>
        <p>The text should be clearly visible and extractable.</p>
        <p>Testing OCR capabilities with various text formats.</p>
    </body>
    </html>
    """
    
    # Write HTML to file
    with open("/tmp/test_ocr.html", "w") as f:
        f.write(html_content)
    
    # Convert HTML to PNG using wkhtmltopdf or similar
    # For now, we'll create a simple text-based image
    print(f"✅ Created test HTML file with text: {test_text}")
    print("📄 Test file location: /tmp/test_ocr.html")
    
    return test_text

def test_screenshot_ocr():
    """Test the actual screenshot OCR functionality"""
    
    print("\n🧪 Testing SmartScreenshot OCR Functionality")
    print("=" * 50)
    
    # Step 1: Create test content
    test_text = create_test_image_with_text()
    
    # Step 2: Instructions for manual testing
    print("\n📋 Manual Testing Instructions:")
    print("1. Open the test file: open /tmp/test_ocr.html")
    print("2. Wait for the page to load in your browser")
    print("3. Press Cmd+Shift+S to trigger SmartScreenshot OCR")
    print("4. Check if text appears in clipboard (Cmd+V)")
    print("5. Verify notification appears")
    
    # Step 3: Check if SmartScreenshot is running
    print("\n🔍 Checking SmartScreenshot Status:")
    result = subprocess.run(
        "ps aux | grep SmartScreenshot | grep -v grep", 
        shell=True, capture_output=True, text=True
    )
    success = result.returncode == 0
    stdout = result.stdout
    
    if success and stdout.strip():
        print("✅ SmartScreenshot is running")
    else:
        print("❌ SmartScreenshot is not running")
        print("   Please start SmartScreenshot first")
        return False
    
    # Step 4: Check permissions
    print("\n🔐 Checking Permissions:")
    
    # Check screen recording permission
    result = subprocess.run(
        "screencapture -x /tmp/test_permission.png 2>&1", 
        shell=True, capture_output=True, text=True
    )
    success = result.returncode == 0
    
    if success:
        print("✅ Screen recording permission granted")
        os.remove("/tmp/test_permission.png")
    else:
        print("❌ Screen recording permission denied")
        print("   Please enable in System Preferences > Security & Privacy > Privacy > Screen Recording")
    
    # Step 5: Test clipboard functionality
    print("\n📋 Testing Clipboard Functionality:")
    
    test_clipboard_text = f"SmartScreenshot Test - {datetime.now().strftime('%H:%M:%S')}"
    result = subprocess.run(
        f'echo "{test_clipboard_text}" | pbcopy', 
        shell=True, capture_output=True, text=True
    )
    success = result.returncode == 0
    
    if success:
        result2 = subprocess.run(
            "pbpaste", 
            shell=True, capture_output=True, text=True
        )
        success2 = result2.returncode == 0
        stdout2 = result2.stdout
        
        if success2 and test_clipboard_text in stdout2:
            print("✅ Clipboard functionality working")
        else:
            print("❌ Clipboard read failed")
    else:
        print("❌ Clipboard write failed")
    
    # Step 6: Provide testing steps
    print("\n🎯 Ready for OCR Testing!")
    print("=" * 50)
    print("Follow these steps to test OCR:")
    print()
    print("1. 📂 Open test file:")
    print("   open /tmp/test_ocr.html")
    print()
    print("2. 📸 Take screenshot with OCR:")
    print("   Press Cmd+Shift+S")
    print()
    print("3. 📋 Check clipboard:")
    print("   Press Cmd+V to paste extracted text")
    print()
    print("4. 🔔 Verify notification:")
    print("   Look for SmartScreenshot notification")
    print()
    print("5. 📚 Check clipboard history:")
    print("   Click SmartScreenshot menu bar icon")
    print()
    print("Expected result: The text from the webpage should be extracted and copied to clipboard")
    print()
    print("If OCR is working, you should see:")
    print(f"   - Text containing: '{test_text}'")
    print("   - Success notification")
    print("   - Text in clipboard history")
    
    return True

def cleanup_test_files():
    """Clean up test files"""
    try:
        os.remove("/tmp/test_ocr.html")
        print("\n🧹 Cleaned up test files")
    except:
        pass

def main():
    print("🚀 SmartScreenshot OCR Functionality Test")
    print("=" * 60)
    
    try:
        success = test_screenshot_ocr()
        
        if success:
            print("\n✅ Test setup complete!")
            print("📝 Follow the manual testing instructions above")
            print("🔍 Check the results and verify OCR functionality")
        else:
            print("\n❌ Test setup failed")
            print("🔧 Please fix the issues above and try again")
            
    except KeyboardInterrupt:
        print("\n⏹️  Test interrupted by user")
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
    finally:
        # Don't cleanup immediately - let user test first
        print("\n💡 To clean up test files later, run:")
        print("   rm /tmp/test_ocr.html")

if __name__ == "__main__":
    main()
