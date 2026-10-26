# Silverflux / Pkg Manager

> SilverArch sync tool: pacman + AUR + mirrors in one command.

![version](https://img.shields.io/badge/version-0.1.0-00BFFF?style=flat-square)
![language](https://img.shields.io/badge/Lua-5.1%20%7C%205.3%2B-000080?style=flat-square&logo=lua&logoColor=white)
![platform](https://img.shields.io/badge/Arch%20Linux-SilverArch-1793D1?style=flat-square&logo=archlinux&logoColor=white)
![license](https://img.shields.io/badge/license-GPL--v3.0-00FF7F?style=flat-square)
![status](https://img.shields.io/badge/status-alpha-FFD700?style=flat-square)

---

<div align="center">

<table>
<tr>
<td align="center" width="33%">
<img src="demo/sync.gif" width="260" alt="silverflux sync"><br>
<b>Full Sync</b><br>
<sub>mirrors → pacman → AUR → cleanup</sub><br><br>
<a href="https://s1lverarch.github.io/linuxdistro/"><img src="https://img.shields.io/badge/Website-00BFFF?style=flat-square&logo=googlechrome&logoColor=white"></a>
<a href="https://github.com/s1lverarch/silverflux"><img src="https://img.shields.io/badge/GitHub-C0C0C0?style=flat-square&logo=github&logoColor=black"></a>
</td>
<td align="center" width="33%">
<img src="demo/mirrors.gif" width="260" alt="silverflux mirrors"><br>
<b>Mirror Ranking</b><br>
<sub>reflector ranks the top N mirrors</sub><br><br>
<a href="https://s1lverarch.github.io/linuxdistro/"><img src="https://img.shields.io/badge/Website-00BFFF?style=flat-square&logo=googlechrome&logoColor=white"></a>
<a href="https://github.com/s1lverarch/silverflux"><img src="https://img.shields.io/badge/GitHub-C0C0C0?style=flat-square&logo=github&logoColor=black"></a>
</td>
<td align="center" width="33%">
<img src="demo/status.gif" width="260" alt="silverflux status"><br>
<b>Status Check</b><br>
<sub>pending repo + AUR updates</sub><br><br>
<a href="https://s1lverarch.github.io/linuxdistro/"><img src="https://img.shields.io/badge/Website-00BFFF?style=flat-square&logo=googlechrome&logoColor=white"></a>
<a href="https://github.com/s1lverarch/silverflux"><img src="https://img.shields.io/badge/GitHub-C0C0C0?style=flat-square&logo=github&logoColor=black"></a>
</td>
</tr>
</table>

<sub>Open Source Projects Hosted at SilverArch · Silvercore (s1lverarch) · <a href="https://github.com/s1lverarch">GitHub</a></sub>

</div>

<img width="1000" height="560" alt="demo" src="https://github.com/user-attachments/assets/c98a1fa3-3830-40ba-9d10-21bc152fa1db" />

Record your own with [asciinema](https://asciinema.org/) and convert with [agg](https://github.com/asciinema/agg):

```bash
asciinema rec demo/sync.cast
agg demo/sync.cast demo/sync.gif
```

### Sample output

```text
 :: ranking top 20 mirrors (reflector)
 ✓ mirrors ranked
 :: syncing repos and upgrading (pacman -Syu)
 :: upgrading AUR packages
 :: keeping last 3 versions (rollback)
 ✓ system up to date
```

---

## ✨ Features

- 🔄 **One command sync**: mirrors, repos, AUR, and cleanup together
- 🌍 **Mirror ranking**: `reflector` or `rate-mirrors`, with automatic rollback on failure
- 📦 **AUR support**: works with `paru` or `yay`, always run as your user, never as root
- ⏪ **Rollback safety**: keeps the last N package versions via `paccache`
- 🔔 **Notifications**: desktop alerts through `notify-send`
- 🪝 **Hooks**: run your own `pre-sync.sh` and `post-sync.sh`
- 🎨 **Styled output**: truecolor SilverArch palette

---

## 🧩 Widgets

Drop these into your status bar, Waybar, or shell prompt.

**Pending updates count** (Waybar custom module):

```json
"custom/silverflux": {
  "exec": "silverflux status | awk '{print $2}' | paste -sd' ' -",
  "interval": 1800,
  "format": " {}",
  "tooltip": true
}
```

**Shell prompt** (zsh):

```zsh
silverflux_pending() {
  local n=$(pacman -Qu 2>/dev/null | wc -l)
  (( n > 0 )) && print -n " %F{yellow}${n} upd%f"
}
PROMPT='$(silverflux_pending) %~ %# '
```

---

## 📥 Installation

### Dependencies

```bash
sudo pacman -S lua pacman-contrib libnotify reflector
# optional AUR helper: paru or yay
# optional faster mirror ranking: rate-mirrors
```

### Install

```bash
git clone https://github.com/s1lverarch/silverflux.git
cd silverflux
sudo install -Dm755 silverflux.lua /usr/local/bin/silverflux
mkdir -p ~/.config/silverflux
cp config.example.lua ~/.config/silverflux/config.lua
```

---

## 🚀 Usage

```bash
sudo silverflux              # full sync (mirrors + pacman + AUR + cleanup)
sudo silverflux mirrors      # rank mirrors only
sudo silverflux aur          # update AUR packages only
     silverflux status       # show pending updates
     silverflux --help
     silverflux --version
```

`-Syu` works as an alias for `sync`.

---

## ⚙️ Configuration

`~/.config/silverflux/config.lua`:

```lua
return {
  aur_helper    = "auto",      -- auto | paru | yay | none
  mirror_method = "reflector", -- reflector | rate-mirrors | none
  mirror_count  = 20,          -- fastest mirrors to keep
  keep_versions = 3,           -- rollback: keep N old versions (0 = off)
  notify        = true,        -- desktop notifications
  hooks         = true,        -- run pre/post-sync scripts
}
```

Hooks live in `~/.config/silverflux/hooks/` and must be executable:

```bash
mkdir -p ~/.config/silverflux/hooks
echo 'echo "backing up /etc..."' > ~/.config/silverflux/hooks/pre-sync.sh
chmod +x ~/.config/silverflux/hooks/pre-sync.sh
```

---

## 🛡️ Safety

- Mirror updates back up the old list to `/etc/pacman.d/mirrorlist.bak` and restore it if ranking fails.
- AUR builds run as the invoking user (`SUDO_USER`), never as root.
- Old package versions are kept for rollback, so a bad update can be undone with `pacman -U`.

---

## 🗺️ Roadmap

- [ ] Pre-sync Timeshift/Snapper snapshot
- [ ] Interactive update picker (vim keys)
- [ ] `.pacnew` merge helper
- [ ] Systemd timer for automatic sync
- [ ] Mirror speed history

---

## 👤 Author

**Silvercore (s1lverarch)**
- Email: s1lv3rcore@proton.me
- Website: https://s1lverarch.github.io/linuxdistro/
- GitHub: https://github.com/s1lverarch

## 📄 License

GPL-v3.0. See `LICENSE`.

## 🔗 Related

- [silvergrab](https://github.com/s1lverarch/silvergrab): package manager (pacman wrapper)
- [SilverSaphire](https://github.com/s1lverarch/SilverSaphire): installer

---

**SilverArch Linux Project**: Made With Love In Tunisia
