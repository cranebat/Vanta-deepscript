# Vanta

Deepwoken script combining:
- **Timings**: APC / Lycoris Rewrite (Weapon windups, specials, criticals)
- **Automations**: Project Rain base (all 16 persistent farms)
- **UI**: Custom Linoria Lib UI (deep purple `#7C5CBF`)
- **Security**: Full `GetLogHistory` nuke & output redirection to `rconsoleprint`

---

## Loadstrings

### 1. Modular / Unbundled (Recommended)
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/cranebat/Vanta-deepscript/main/vanta%20master/init.lua"))()
```

### 2. Single-File Bundled
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/cranebat/Vanta-deepscript/main/Vanta.lua"))()
```