# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Self Recruitment, Spam & Responder** is a World of Warcraft addon (version 3.04.2) that provides three main features. This addon is compatible with both **TBC Anniversary** (Interface 20501) and **Wrath Anniversary** (Interface 30400):

1. **Repondeur** - An auto-responder system that sends whispered replies to players based on keyword matching
2. **AutoFlood** - A message flooding utility that sends repeated messages to a chat channel at a configurable rate
3. **MessageQueue** - A message queueing system that respects WoW's message rate limits and prevents spam detection

## Technology Stack

- **Language**: Lua (WoW addon scripting language)
- **UI Framework**: WoW FrameXML (frames defined in `.xml`, logic in `.lua`)
- **Localization**: Multi-language support (English, French, German)
- **State Persistence**: SavedVariables (per-character and per-account storage)

## Architecture

### Core Files and Responsibilities

- **SelfRecruitment.toc** - Addon metadata (version, dependencies, SavedVariables declarations)
- **Repondeur.xml** - UI frame definitions for the auto-responder GUI window
- **Repondeur.lua** - Main auto-responder logic, event handling, and GUI management
- **AutoFlood.lua** - Message flooding implementation with rate limiting
- **MessageQueue.lua** - Core message queueing system that coordinates between Repondeur and AutoFlood
- **localization.lua, localization.en.lua, localization.fr.lua, localization.de.lua** - Localized strings

### Key Architectural Concepts

**Event-Driven Design**: The addon registers for WoW events:
- `VARIABLES_LOADED` - Initialize configuration when SavedVariables are ready
- `PLAYER_ENTERING_WORLD` / `PLAYER_LEAVING_WORLD` - Track player state
- `CHAT_MSG_WHISPER` / `CHAT_MSG_BN_WHISPER` - Detect incoming whispers to trigger auto-responses
- `GROUP_INVITE_CONFIRMATION` - Handle group invitations

**SavedVariables Storage**:
- `RepondeurMainOptions` (per-character) - Stores module state, spam check settings, UI scaling
- `RepondeurOptions` (per-character) - Stores all auto-response rules with keywords and responses
- `AF_characterConfig` (per-character) - AutoFlood configuration (message, channel, rate)
- `AF_config` (account-wide) - Legacy storage, being phased out

**Message Rate Limiting**: The MessageQueue module manages a queue of chat messages and processes them based on hardware events (mouse, keyboard, gamepad) to avoid triggering Blizzard's flood detection. Messages are queued and sent when player interaction occurs.

**Multi-Response System**: Each character can have multiple auto-responses. Each response entry contains:
- Keywords (table of strings to match against incoming whispers)
- Response text (can be plain text with links or executable Lua code)
- Active flag (whether this response is enabled)
- Script flag (whether to execute as Lua code)
- Options (filtering: by guild/party/raid/friends/specific names, and output routing)

## Development Workflow

### Testing Changes

1. Edit `.lua` or `.xml` files
2. In-game, use `/reload` (or `/rl`) to reload the addon
3. Use `/rep` or `/repondeur` or `/recruit` to open the GUI
4. Use `/floodhelp` to see AutoFlood commands
5. Check the chat frame for addon messages and debug output

### Common Commands

- `/rep` or `/repondeur` or `/recruit` - Open the auto-responder GUI
- `/flood [on|off]` - Enable/disable message flooding
- `/floodmsg <message>` - Set the flood message
- `/floodchan <channel>` - Set the flood channel (say, yell, guild, party, raid, etc.)
- `/floodrate <seconds>` - Set the flood interval (minimum depends on configuration)
- `/floodinfo` - Display current flood settings
- `/floodhelp` - Display AutoFlood help
- `/mq` or `/msgqueue` or `/messagequeue` - Manually process the message queue

### Localization

All user-facing strings are defined in `localization.lua` and language-specific files. When adding new strings:
1. Add the string constant to `localization.lua` with a descriptive name (e.g., `MY_NEW_LABEL_TEXT`)
2. Add translations to `localization.en.lua`, `localization.fr.lua`, `localization.de.lua`
3. Reference the constant name in your `.lua` code (e.g., `getglobal("MY_NEW_LABEL_TEXT")`)

### Adding Features

When modifying the auto-responder:
- Response filtering logic is in the `Options` table within each response entry
- Keyword matching is performed in event handlers registered on `RepondeurFrame`
- The response delivery respects the `Tell` options (can send to party/raid/guild instead of just whisper)

When modifying message flooding:
- Rate limiting is enforced by checking `AF_characterConfig.rate` and the elapsed time in `AutoFlood_OnUpdate`
- The `MAX_RATE` constant (currently 10) defines the minimum allowed interval
- Messages are queued via `MessageQueue.SendChatMessage()` to coordinate with the responder system

## Known Limitations and Constraints

- WoW enforces a hard message rate limit (~1 message per second globally across all addons)
- The spam check in Repondeur prevents responding to the same player too frequently (configurable via `SpamTimer`)
- Message flooding respects hardware events; messages only send while the queue is actively processing
- The UI frame is defined in XML and cannot be dynamically generated; modifications require editing `Repondeur.xml`

## Cross-Version Compatibility (TBC ↔ Wrath)

The addon includes a compatibility layer to support both TBC (20501) and Wrath (30400) anniversary servers. Key compatibility considerations:

**APIs that differ:**
- `C_Timer.NewTimer()` - Only available in Wrath. TBC uses frame-based timers as fallback
- `Mixin()` - Only available in Wrath. TBC uses manual table merging implementation
- `GetAddOnMetadata()` - Available in both, but fallback to hardcoded version in TBC
- `SetColorTexture()` - May differ; uses `SetTexture()` fallback for TBC
- GamePad events - Not supported in TBC, safely skipped with guards

**When modifying code:**
- Check if new APIs are available in both versions before using them
- Use the compatibility helpers (`SetTextureSafe`, `EnableGamePadSafe`, etc.) already defined in `MessageQueue.lua`
- Add fallback implementations for any Wrath-specific features
- Test changes on both TBC and Wrath servers if possible

**Addon initialization:**
- The `WOW_PROJECT_ID` constant is used to detect the current version
- `isTBC` and `isWrath` flags can be used in other files for version-specific logic
- Version info in comments should reference both supported versions

## Important Notes

- Do not modify the `SelfRecruitment.toc` Interface version without ensuring compatibility with the appropriate version(s)
- The `.toc` file uses `X-Min-Interface-TBC: 20501` and `X-Min-Interface-Wrath: 30400` to declare version support
- SavedVariables are loaded after `PLAYER_ENTERING_WORLD`, so initialization checks the `VariablesLoaded` flag
- The addon uses `hooksecurefunc` for item link handling; be careful when modifying this
- Use `MessageQueue.Enqueue()` instead of direct `SendChatMessage()` calls to respect rate limiting
- Always use the compatibility helpers when adding code that uses version-specific APIs
