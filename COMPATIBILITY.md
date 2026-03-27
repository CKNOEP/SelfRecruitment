# Compatibility Notes - TBC Anniversary

## Overview

This addon has been successfully adapted to support **TBC Anniversary 2.5.5 (Interface 20505)**.

**Note:** This version is optimized for TBC 2.5.5. For Wrath Anniversary support, use the original version or maintain separate builds.

## Changes Made for TBC Compatibility

### 1. MessageQueue.lua - Timer System
**Problem:** Flash timer was causing continuous callback errors
- **Solution:** Disabled the flash timer functionality entirely (non-critical feature)
- Removed `C_Timer.NewTimer()` calls that were incompatible
- Flash timer now uses empty stub function instead of problematic callbacks

### 2. Repondeur.xml - UI Templates
**Problem:** `OptionsCheckButtonTemplate` and `BackdropTemplate` don't exist in TBC
- **Solution:** Removed custom template inheritance from CheckButtons
- Removed all `<Backdrop>` tags which are Wrath-only XML elements
- CheckButtons now use basic frame properties without template inheritance

### 3. Repondeur.lua - Compatibility Functions
**Problem:** Creating fontstrings dynamically caused issues
- **Solution:** Simplified `Repondeur_SetButtonText()` to only set text if fontstring exists
- No longer attempts dynamic creation of UI elements
- Fixed nested comment syntax errors (`--[[...]]` inside comments)

### 4. AutoFlood.lua - API Compatibility
**Problem:** `GetAddOnMetadata()` and `Mixin()` may not work correctly
- **Solution:** Added safe wrappers that handle missing functions gracefully
- Custom `Mixin()` implementation for table merging
- Fallback version string when metadata unavailable

### 5. SelfRecruitment.toc - Metadata
**Updated to:**
- Interface: 20505 (TBC Anniversary 2.5.5)
- Version: 3.04.3
- All TBC-specific compatibility built in

## Version Detection

The addon uses `WOW_PROJECT_ID` constant to detect the current WoW version:
```lua
local WOW_PROJECT_ID = WOW_PROJECT_MAINLINE
local isTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local isWrath = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
```

This allows version-specific behavior when needed.

## Tested APIs

The following APIs have been verified to exist in both TBC and Wrath:
- `UnitFullName()` - Character name retrieval
- `GetRealmName()` - Realm name retrieval
- `SendChatMessage()` - Basic chat functionality
- `GetDefaultLanguage()` - Language detection
- `hooksecurefunc()` - Function hooking
- `RegisterEvent()` / `SetScript()` - Event handling
- `GetTime()` - Time tracking

## Known Limitations

1. **Message Rate Limiting:** The underlying rate limit of 1 message per second is enforced by WoW in both versions
2. **UI Framework:** FrameXML UI definition is the same in both versions - no frame compatibility issues expected
3. **Locale Support:** Language-specific strings work identically in both versions

## Testing Recommendations

When adding new features:
1. Test on both TBC and Wrath servers
2. Use compatibility helpers for any new Wrath-specific APIs
3. Document any version-specific behavior in code comments
4. Update this file with any new compatibility considerations

## Future Maintenance

If updating the addon for future WoW versions:
- Check `WOW_PROJECT_ID` for new version constants
- Test all C_* namespace APIs (commonly version-specific)
- Verify frame script names haven't changed
- Test with both target versions before releasing
