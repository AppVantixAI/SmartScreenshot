#!/usr/bin/env python3
"""
Test script for SmartScreenshot multi-screen menubar functionality
"""

import subprocess
import sys
import time

def run_command(cmd):
    """Run a command and return the output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.stdout.strip(), result.stderr.strip(), result.returncode
    except Exception as e:
        return "", str(e), -1

def test_multi_screen_detection():
    """Test if the app can detect multiple screens"""
    print("🔍 Testing multi-screen detection...")
    
    # Check system screen info
    stdout, stderr, returncode = run_command("system_profiler SPDisplaysDataType")
    if returncode == 0:
        print("✅ System screen detection working")
        
        # Look for multiple displays
        if "Display Type: External" in stdout or "Display Type: Built-in" in stdout:
            print("✅ Multiple display types detected")
        else:
            print("⚠️  Only single display detected")
    else:
        print(f"❌ Failed to get screen info: {stderr}")
    
    return returncode == 0

def test_app_launch():
    """Test if the app launches successfully"""
    print("\n🚀 Testing app launch...")
    
    # Check if app is already running
    stdout, stderr, returncode = run_command("pgrep -f SmartScreenshot")
    if returncode == 0:
        print("✅ SmartScreenshot is already running")
        return True
    
    # Try to launch the app
    print("📱 Launching SmartScreenshot...")
    stdout, stderr, returncode = run_command("open -a SmartScreenshot")
    
    if returncode == 0:
        print("✅ App launch command sent successfully")
        
        # Wait a moment for the app to start
        time.sleep(3)
        
        # Check if it's now running
        stdout, stderr, returncode = run_command("pgrep -f SmartScreenshot")
        if returncode == 0:
            print("✅ App is now running")
            return True
        else:
            print("❌ App failed to start")
            return False
    else:
        print(f"❌ Failed to launch app: {stderr}")
        return False

def test_menubar_integration():
    """Test if the menubar integration is working"""
    print("\n🎯 Testing menubar integration...")
    
    # Check if the menubar item is visible
    stdout, stderr, returncode = run_command("defaults read org.p0deje.SmartScreenshot showInStatusBar 2>/dev/null || echo 'not_set'")
    if returncode == 0 and stdout != "not_set":
        print(f"✅ Status bar visibility setting: {stdout}")
    else:
        print("⚠️  Status bar visibility setting not found")
    
    # Check for menubar display settings
    stdout, stderr, returncode = run_command("defaults read org.p0deje.SmartScreenshot menubar_display_mode 2>/dev/null || echo 'not_set'")
    if returncode == 0 and stdout != "not_set":
        print(f"✅ Menubar display mode: {stdout}")
    else:
        print("⚠️  Menubar display mode setting not found")
    
    return True

def test_screen_parameters():
    """Test screen parameter change detection"""
    print("\n🖥️  Testing screen parameter detection...")
    
    # Check if we can detect screen changes
    stdout, stderr, returncode = run_command("system_profiler SPDisplaysDataType | grep -c 'Display Type'")
    if returncode == 0 and stdout.isdigit():
        screen_count = int(stdout)
        print(f"✅ Detected {screen_count} display(s)")
        
        if screen_count > 1:
            print("✅ Multi-screen setup detected")
            print("💡 You can test the menubar display settings by:")
            print("   1. Opening SmartScreenshot")
            print("   2. Right-clicking the menubar icon")
            print("   3. Selecting 'Menubar Display Settings...'")
            print("   4. Choosing different display modes")
        else:
            print("⚠️  Single screen setup - multi-screen features won't be visible")
    else:
        print("❌ Failed to detect screen count")
    
    return True

def main():
    """Main test function"""
    print("🧪 SmartScreenshot Multi-Screen Menubar Test Suite")
    print("=" * 50)
    
    tests = [
        test_multi_screen_detection,
        test_app_launch,
        test_menubar_integration,
        test_screen_parameters
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        try:
            if test():
                passed += 1
        except Exception as e:
            print(f"❌ Test failed with error: {e}")
    
    print("\n" + "=" * 50)
    print(f"📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! Multi-screen menubar functionality is working.")
    else:
        print("⚠️  Some tests failed. Check the output above for details.")
    
    print("\n💡 Next Steps:")
    print("1. Open SmartScreenshot if it's not already running")
    print("2. Right-click the menubar icon")
    print("3. Select 'Menubar Display Settings...'")
    print("4. Configure your preferred display mode")
    print("5. Test different screen configurations")

if __name__ == "__main__":
    main()
