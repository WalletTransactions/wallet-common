#!/usr/bin/env bash
# Копирует util/ этого репозитория в <сервис>/third_party/wallet-common/ —
# так же, как там лежат httplib.h и nlohmann: каждый сервис собирается из
# своего репозитория без внешних зависимостей (Containerfile, CI не меняются).
#
#   bash wallet-common/scripts/vendor.sh                  # во все сервисы-соседи
#   bash wallet-common/scripts/vendor.sh ../wallet-api    # в указанные
#   bash wallet-common/scripts/vendor.sh --check [...]    # только сверить, exit 1 при расхождении
#
# Сервис-сосед — папка рядом с wallet-common, у которой уже есть
# third_party/wallet-common/ (первый раз — указать путь явно).
# Копию в сервисе руками не править: правка — здесь, потом vendor.sh.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
check=0
if [[ "${1:-}" == "--check" ]]; then
    check=1
    shift
fi

targets=("$@")
if [[ ${#targets[@]} -eq 0 ]]; then
    for d in "$root"/../*/; do
        [[ -d "$d/third_party/wallet-common" ]] && targets+=("$d")
    done
fi
if [[ ${#targets[@]} -eq 0 ]]; then
    echo "нет сервисов с third_party/wallet-common — укажите путь явно" >&2
    exit 2
fi

version="$(tr -d '[:space:]' < "$root/VERSION")"
commit="$(git -C "$root" describe --tags --always --dirty --abbrev=8 2>/dev/null || echo unknown)"

status=0
for t in "${targets[@]}"; do
    t="$(cd "$t" && pwd)"
    dest="$t/third_party/wallet-common"
    name="$(basename "$t")"
    if [[ $check -eq 1 ]]; then
        if diff -r -q -x VENDORED "$root/util" "$dest/util" > /dev/null 2>&1; then
            echo "ok       $name"
        else
            echo "differs  $name"
            status=1
        fi
        continue
    fi
    rm -rf "$dest/util"
    mkdir -p "$dest"
    cp -r "$root/util" "$dest/util"
    printf 'wallet-common %s (%s)\nНе править: источник — репозиторий wallet-common, обновление — scripts/vendor.sh.\n' \
        "$version" "$commit" > "$dest/VENDORED"
    echo "vendored $name <- $version ($commit)"
done
exit $status
