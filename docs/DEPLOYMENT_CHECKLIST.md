# 🚀 SmartScreenshot Deployment Checklist

**IMPORTANT: Complete this checklist before every release deployment**

## 📋 Pre-Release Checklist

### 1. 🏷️ Version Management
- [ ] **Update Version Numbers**:
  - [ ] `SmartScreenshot/Info.plist` - Update `CFBundleShortVersionString` and `CFBundleVersion`
  - [ ] `appcast.xml` - Update version numbers and dates
  - [ ] `README.md` - Update version references
  - [ ] `SmartScreenshot/Settings/GeneralSettingsPane.swift` - Update "Current Version" display

### 2. 🔄 GitHub Release Preparation
- [ ] **Create New Release on GitHub**:
  - [ ] Go to `https://github.com/AppVantixAI/SmartScreenshot/releases`
  - [ ] Click "Create a new release"
  - [ ] Tag version (e.g., `v2.6.0`)
  - [ ] Release title (e.g., `SmartScreenshot 2.6.0`)
  - [ ] Write release notes describing new features/fixes
  - [ ] Upload the compiled `.app.zip` file

### 3. 📡 Appcast.xml Updates
- [ ] **Update `appcast.xml`**:
  - [ ] Update `<pubDate>` to current date
  - [ ] Update `<sparkle:version>` (build number)
  - [ ] Update `<sparkle:shortVersionString>` (marketing version)
  - [ ] Update `<enclosure url="">` to point to new release ZIP
  - [ ] Update `<releaseNotesLink>` to point to new GitHub release

### 4. 🧪 Quality Assurance
- [ ] **Testing**:
  - [ ] Build and test on macOS 14.0+
  - [ ] Test all SmartScreenshot features (OCR, region selection, bulk processing)
  - [ ] Verify update checking works from new appcast
  - [ ] Test accessibility features
  - [ ] Verify all keyboard shortcuts work
  - [ ] Test on both Intel and Apple Silicon Macs

### 5. 📦 Build Preparation
- [ ] **Xcode Build**:
  - [ ] Clean build folder (`Product → Clean Build Folder`)
  - [ ] Build for Release configuration
  - [ ] Archive the app
  - [ ] Export as Developer ID distribution
  - [ ] Create `.app.zip` file for distribution

### 6. 🔐 Code Signing & Notarization
- [ ] **Security**:
  - [ ] Verify code signing with your Developer ID
  - [ ] Submit for Apple notarization
  - [ ] Wait for notarization approval
  - [ ] Verify notarization status

### 7. 📚 Documentation Updates
- [ ] **Update Documentation**:
  - [ ] `README.md` - Add new features/changes
  - [ ] `CHANGELOG.md` - Document all changes
  - [ ] Update any user guides or help files
  - [ ] Review and update license information

### 8. 🌐 Repository Sync
- [ ] **Git Operations**:
  - [ ] Commit all changes with descriptive message
  - [ ] Push to `master` branch
  - [ ] Verify changes appear on GitHub
  - [ ] Tag the release commit

## 🚨 Critical Deployment Steps

### **BEFORE PUSHING TO GITHUB:**
1. **Double-check all version numbers** in `appcast.xml` and `Info.plist`
2. **Verify the appcast URL** points to your repository: `https://raw.githubusercontent.com/AppVantixAI/SmartScreenshot/master/appcast.xml`
3. **Ensure the release ZIP URL** is correct in `appcast.xml`
4. **Test the update mechanism** with the new appcast

### **AFTER PUSHING TO GITHUB:**
1. **Wait for GitHub Pages** to update (if using GitHub Pages for appcast)
2. **Test the update process** from a previous version
3. **Monitor for any user-reported issues**
4. **Update release notes** if needed

## 📱 Distribution Channels

### **Primary Distribution:**
- [ ] **GitHub Releases** - Main distribution point
- [ ] **Appcast Updates** - Automatic updates for existing users

### **Optional Distribution:**
- [ ] **Homebrew Cask** - If you want to support Homebrew users
- [ ] **MacPorts** - If you want to support MacPorts users
- [ ] **Direct Downloads** - From your website (if applicable)

## 🔍 Post-Deployment Verification

### **24 Hours After Release:**
- [ ] **Monitor GitHub Issues** for bug reports
- [ ] **Check update success rate** in analytics (if available)
- [ ] **Verify appcast is accessible** from different locations
- [ ] **Test update process** on clean macOS installation

### **1 Week After Release:**
- [ ] **Review user feedback** and GitHub discussions
- [ ] **Plan next release** based on feedback
- [ ] **Update roadmap** if needed

## 📝 Release Notes Template

```markdown
## SmartScreenshot [VERSION]

### 🆕 New Features
- Feature 1
- Feature 2

### 🐛 Bug Fixes
- Fixed issue with...
- Resolved problem in...

### 🔧 Improvements
- Enhanced performance of...
- Better error handling for...

### 📱 System Requirements
- macOS 14.0 or later
- Intel or Apple Silicon Mac

### 🔗 Download
- [Download SmartScreenshot [VERSION]](https://github.com/AppVantixAI/SmartScreenshot/releases/download/[VERSION]/SmartScreenshot.app.zip)

### 📚 Documentation
- [Full Documentation](https://github.com/AppVantixAI/SmartScreenshot)
- [Report Issues](https://github.com/AppVantixAI/SmartScreenshot/issues)
```

## ⚠️ Common Pitfalls to Avoid

1. **❌ Forgetting to update version numbers** in multiple files
2. **❌ Pushing appcast changes before creating GitHub release**
3. **❌ Not testing the update mechanism before release**
4. **❌ Releasing without proper code signing/notarization**
5. **❌ Forgetting to update the "Current Version" display in settings**

## 🆘 Emergency Rollback

If a release has critical issues:

1. **Immediately create a hotfix release**
2. **Update appcast.xml** to point to the previous working version
3. **Push changes** to GitHub
4. **Communicate with users** about the issue
5. **Investigate and fix** the problem
6. **Release a corrected version**

---

**Last Updated**: September 1, 2025  
**Next Review**: Before next release  
**Maintainer**: Camden Burke (AppVantixAI)

---

*Remember: A successful deployment is the result of careful preparation and thorough testing. Take your time and follow this checklist step by step!* 🎯
