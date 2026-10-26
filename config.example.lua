-- ~/.config/silverflux/config.lua
return {
  aur_helper    = "auto",      -- auto | paru | yay | none
  mirror_method = "reflector", -- reflector | rate-mirrors | none
  mirror_count  = 20,
  keep_versions = 3,           -- rollback: keep N old versions (0 = off)
  notify        = true,
  hooks         = true,
}
