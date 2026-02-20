# Ironcore Arena v0.1.0 Release Checklist

## Pre-Release Verification

### ✅ Core Functionality
- [x] Game launches without errors
- [x] Main menu displays correctly
- [x] Tutorial runs completely
- [x] Builder allows bot creation
- [x] Battle system works (win/loss detection)
- [x] Shop functions (buy components)
- [x] Save/Load works correctly
- [x] Campaign progression saves
- [x] All 4 arenas playable

### ✅ Integration Tests
Run: `./test.sh`
- [x] DataLoader loads all components
- [x] GameState initializes correctly
- [x] Arena scenes instantiate
- [x] BattleManager setups battles
- [x] ShopManager shows components

### ✅ Build Process
Run: `./build.sh 0.1.0 all`

**Windows:**
- [ ] Build succeeds without errors
- [ ] Executable runs on Windows 10/11
- [ ] No console window shown (release mode)
- [ ] Icon displays correctly

**Linux:**
- [ ] Build succeeds without errors
- [ ] Executable runs on Ubuntu 22.04+
- [ ] Dependencies clearly stated

**macOS:**
- [ ] Build succeeds without errors
- [ ] App bundle runs on macOS 12+
- [ ] Notarization (if distributing)

---

## Release Artifacts

### Build Outputs
```
builds/
├── ironcore-arena-v0.1.0-windows.exe
├── ironcore-arena-v0.1.0-linux.x86_64
└── ironcore-arena-v0.1.0-macos.zip
```

### Documentation
- [x] README.md updated
- [x] PLAYABLE_STATUS.md current
- [x] CHANGELOG.md created
- [x] LICENSE file included

### Store Assets (if applicable)
- [ ] Screenshots (6-10 images)
- [ ] Trailer/video (optional)
- [ ] Store description
- [ ] Tags/keywords

---

## Known Issues

### None Critical ✅
All known issues are minor or cosmetic.

### Minor Issues
- [ ] Procedural sprites are placeholders
- [ ] Sound effects synthesized (not recorded)
- [ ] No music tracks yet

---

## Post-Release Plans

### v0.2.0 Goals
- Replace procedural sprites with final art
- Add authentic sound effects
- Include background music
- Steam integration
- Achievements system

---

## Sign-Off

**Release Manager:** _________________  
**Date:** _________________  
**Approved for Release:** [ ] Yes  [ ] No

---

## Version History

### v0.1.0 (Current)
- Initial MVP release
- 4 campaign arenas
- Tutorial system
- Procedural art assets
- Full gameplay loop

### Future Versions
- v0.2.0: Art and audio polish
- v0.3.0: Additional content
- v1.0.0: Full release
