# Maintainer: Silvercore (s1lverarch) <s1lv3rcore@proton.me>
# Website: https://s1lverarch.github.io/linuxdistro/

pkgname=silverflux
pkgver=0.1.0
pkgrel=1
pkgdesc="SilverArch sync tool: pacman + AUR + mirrors in one command"
arch=('any')
url="https://github.com/s1lverarch/silverflux"
license=('GPL-3.0-only')
depends=('lua' 'pacman')
optdepends=(
  'reflector: rank mirrors (default mirror method)'
  'rate-mirrors: faster mirror ranking alternative'
  'pacman-contrib: paccache for keeping rollback versions'
  'libnotify: desktop notifications (notify-send)'
  'paru: AUR helper'
  'yay: AUR helper'
)
source=("$pkgname-$pkgver.tar.gz::https://github.com/s1lverarch/$pkgname/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=('SKIP')

package() {
  cd "$srcdir/$pkgname-$pkgver"

  install -Dm755 cmd/silverflux.lua "$pkgdir/usr/bin/silverflux"
  install -Dm644 config.example.lua "$pkgdir/usr/share/doc/$pkgname/config.example.lua"
  install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
