# Multi-Screen Menubar Guide for SmartScreenshot

## Overview

SmartScreenshot now includes advanced multi-screen menubar support that allows users to configure how the menubar icon appears across different displays. This feature provides intelligent screen detection and configuration options while working within macOS limitations.

## 🖥️ **Display Modes**

### 1. **Primary Display Only** (Default)
- **Behavior**: Icon appears only on the main/primary display
- **Use Case**: Simple single-screen setups or when you prefer the icon on the main screen
- **Limitation**: Icon won't be visible on secondary displays

### 2. **Preferred Screen**
- **Behavior**: Icon appears on a user-selected screen
- **Use Case**: When you want the icon on a specific secondary display
- **Features**: 
  - Dropdown selection of available screens
  - Automatic validation of screen selection
  - Persistence across app launches

### 3. **Active Screen**
- **Behavior**: Icon follows the currently active screen (where the key window is)
- **Use Case**: Dynamic multi-screen workflows where you want the icon to follow your active work
- **Features**:
  - Real-time screen tracking
  - Automatic updates when switching between screens
  - Best option for multi-screen productivity

### 4. **All Available Screens**
- **Behavior**: Attempts to show icon on all screens (with limitations)
- **Use Case**: When you want maximum accessibility across all displays
- **Limitations**: Due to macOS restrictions, the icon can only appear on one menu bar at a time

## 🔧 **How to Configure**

### Accessing the Settings
1. **Right-click** the SmartScreenshot menubar icon
2. Select **"Menubar Display Settings..."**
3. Choose your preferred **Display Mode**
4. Configure additional options as needed

### Screen Selection (Preferred Screen Mode)
1. Choose **"Preferred Screen"** from the Display Mode picker
2. Select your desired screen from the dropdown
3. The app will automatically validate your selection
4. Settings are saved automatically

### Advanced Options
- **Show on All Screens**: Toggle for maximum multi-screen support
- **Screen Information**: View detailed information about each detected screen
- **Real-time Updates**: Settings update automatically when screen configuration changes

## 📱 **macOS Limitations & Workarounds**

### **Important Limitation**
Due to macOS system restrictions, **NSStatusItem objects can only appear on one menu bar at a time**. This is a fundamental limitation of the operating system, not a SmartScreenshot restriction.

### **What This Means**
- The menubar icon will only be visible on the screen that currently has the menu bar
- You cannot have the icon simultaneously visible on multiple screens
- The icon's visibility depends on which screen the system menu bar is displayed on

### **Workarounds & Solutions**

#### **Option 1: Move the Menu Bar**
1. Go to **System Preferences > Displays**
2. Click the **"Arrangement"** tab
3. **Drag the menu bar** to your preferred screen
4. The SmartScreenshot icon will now appear on that screen

#### **Option 2: Use Active Screen Mode**
- Set Display Mode to **"Active Screen"**
- The app will automatically track which screen you're working on
- Provides the best multi-screen experience within macOS limitations

#### **Option 3: Preferred Screen Mode**
- Select a specific screen where you want the icon to appear
- Useful when you have a primary work screen

## 🎯 **Best Practices**

### **For Single Screen Users**
- Use **"Primary Display Only"** mode
- No additional configuration needed

### **For Dual Screen Users**
- Use **"Active Screen"** mode for dynamic following
- Or use **"Preferred Screen"** mode to pin to your main work screen

### **For Multi-Screen Workstations**
- Use **"Active Screen"** mode for maximum flexibility
- Consider **"Preferred Screen"** mode if you have a primary work area
- Use the screen information panel to understand your setup

### **For Developers & Power Users**
- Monitor the console output for detailed configuration information
- Use the test script to verify functionality
- Check screen parameter change notifications

## 🧪 **Testing & Verification**

### **Built-in Testing**
The app includes comprehensive logging for debugging:
- Console output shows current screen configuration
- Real-time updates when settings change
- Screen parameter change detection

### **Manual Testing**
1. **Change Display Modes**: Switch between different modes to see behavior
2. **Screen Detection**: Add/remove displays to test automatic detection
3. **Menu Bar Movement**: Move the system menu bar between screens
4. **Active Window Tracking**: Switch between windows on different screens

### **Test Script**
Run the included test script to verify functionality:
```bash
cd scripts
python3 test_multi_screen_menubar.py
```

## 🔍 **Troubleshooting**

### **Common Issues**

#### **Icon Not Visible on Secondary Screen**
- **Cause**: macOS limitation - icons can only appear on one menu bar
- **Solution**: Move the system menu bar to the desired screen

#### **Settings Not Saving**
- **Cause**: Permission or file system issues
- **Solution**: Check app permissions and restart the app

#### **Screen Detection Issues**
- **Cause**: Display configuration changes not detected
- **Solution**: Restart the app or check system display settings

#### **Performance Issues**
- **Cause**: Too frequent screen change detection
- **Solution**: Use "Primary Display Only" or "Preferred Screen" modes

### **Debug Information**
Check the console for detailed information:
- Screen detection results
- Configuration changes
- Error messages
- Performance metrics

## 🚀 **Future Enhancements**

### **Planned Features**
- **Smart Screen Detection**: Improved algorithms for screen identification
- **Custom Screen Names**: User-defined names for screens
- **Hotkey Support**: Keyboard shortcuts for quick screen switching
- **Profile Support**: Saved configurations for different setups

### **macOS Updates**
- Monitor for new APIs that might enable true multi-screen menubar support
- Adapt to changes in display management systems
- Leverage new accessibility features when available

## 📚 **Technical Details**

### **Architecture**
- **MenubarManager**: Core service managing display logic
- **Screen Detection**: Real-time monitoring of screen configuration
- **Settings Integration**: Persistent storage of user preferences
- **Notification System**: Real-time updates for configuration changes

### **APIs Used**
- **NSScreen**: Screen detection and information
- **NSStatusItem**: Menubar icon management
- **NotificationCenter**: System event monitoring
- **UserDefaults**: Settings persistence

### **Performance Considerations**
- **Efficient Monitoring**: Minimal impact on system performance
- **Smart Updates**: Only update when necessary
- **Memory Management**: Proper cleanup of observers and resources

## 🤝 **Support & Feedback**

### **Getting Help**
- Check the console output for error messages
- Run the test script to identify issues
- Review this documentation for common solutions

### **Reporting Issues**
- Include your macOS version
- Describe your display setup
- Provide console output if available
- Mention any error messages

### **Feature Requests**
- Suggest improvements to the multi-screen functionality
- Request additional display modes
- Propose new configuration options

---

## 📋 **Quick Reference**

| Mode | Best For | Limitations |
|------|----------|-------------|
| Primary Only | Single screen, simplicity | No multi-screen support |
| Preferred Screen | Specific screen preference | Static positioning |
| Active Screen | Dynamic workflows | Requires active window |
| All Screens | Maximum accessibility | macOS limitation applies |

**Remember**: The menubar icon can only appear on one screen at a time due to macOS restrictions. Use the "Active Screen" mode for the best multi-screen experience.
