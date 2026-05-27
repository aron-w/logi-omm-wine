#!/usr/bin/env bash
set -euo pipefail

repo_root="$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1
  pwd -P
)"
script_dir="${OMME_TEST_BIN_DIR:-$repo_root/bin}"

tmp_root="$(mktemp -d)"
base_path="$PATH"
trap 'rm -rf "$tmp_root"' EXIT

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

assert_log() {
  expected="$1"
  actual="$(cat "$tmp_root/log" 2>/dev/null || true)"
  [ "$actual" = "$expected" ] || fail "expected log '$expected', got '$actual'"
}

write_fake() {
  target="$1"
  printf '#!%s\n' "$BASH" >"$target"
  cat >>"$target"
  chmod +x "$target"
}

reset_fake_path() {
  rm -rf "$tmp_root/bin" "$tmp_root/home" "$tmp_root/log"
  mkdir -p "$tmp_root/bin" "$tmp_root/home"
  export HOME="$tmp_root/home"
  export XDG_DATA_HOME="$tmp_root/home/data"
  export XDG_CACHE_HOME="$tmp_root/home/cache"
  export OMME_WINEPREFIX="$tmp_root/home/prefix"
  export PATH="$tmp_root/bin:$base_path"
  unset OMME_EXE OMME_DATA_DIR OMME_ALLOW_DOWNLOAD OMME_WINEDEBUG

  write_fake "$tmp_root/bin/wine" <<'EOF'
printf 'wine' >>"$TEST_LOG"
for arg in "$@"; do
  printf ' <%s>' "$arg" >>"$TEST_LOG"
done
printf '\n' >>"$TEST_LOG"
EOF
  write_fake "$tmp_root/bin/wineboot" <<'EOF'
printf 'wineboot' >>"$TEST_LOG"
for arg in "$@"; do
  printf ' <%s>' "$arg" >>"$TEST_LOG"
done
printf '\n' >>"$TEST_LOG"
EOF
  write_fake "$tmp_root/bin/winetricks" <<'EOF'
printf 'winetricks' >>"$TEST_LOG"
for arg in "$@"; do
  printf ' <%s>' "$arg" >>"$TEST_LOG"
done
printf '\n' >>"$TEST_LOG"
EOF
  write_fake "$tmp_root/bin/sha256sum" <<'EOF'
printf '%s  %s\n' "$TEST_SHA256SUM" "$1"
EOF
  write_fake "$tmp_root/bin/curl" <<'EOF'
printf 'curl' >>"$TEST_LOG"
while [ "$#" -gt 0 ]; do
  if [ "$1" = "-o" ]; then
    shift
    printf 'download' >"$1"
    break
  fi
  shift
done
printf '\n' >>"$TEST_LOG"
EOF

  export TEST_LOG="$tmp_root/log"
  export TEST_SHA256SUM="aec76587f1d07c51667c140c730a38f82675fbe2d898e79413372146b9632358"
}

reset_fake_path
if bash "$script_dir/omme" >/dev/null 2>"$tmp_root/stderr"; then
  fail "omme without marker should fail"
fi
assert_log ""

reset_fake_path
mkdir -p "$OMME_WINEPREFIX"
touch "$OMME_WINEPREFIX/.omme-initialized-dotnet48"
export OMME_EXE="$tmp_root/OnboardMemoryManager.exe"
touch "$OMME_EXE"
if bash "$script_dir/omme" --example >/dev/null 2>"$tmp_root/stderr"; then
  fail "omme with legacy marker should fail"
fi
assert_log ""

reset_fake_path
mkdir -p "$OMME_WINEPREFIX"
touch "$OMME_WINEPREFIX/.omme-initialized-v2"
export OMME_EXE="$tmp_root/OnboardMemoryManager.exe"
touch "$OMME_EXE"
bash "$script_dir/omme" --example
assert_log "wine <$OMME_EXE> <--example>"

reset_fake_path
mkdir -p "$OMME_WINEPREFIX"
touch "$OMME_WINEPREFIX/.omme-initialized-v2"
bash "$script_dir/omme-init"
assert_log ""

reset_fake_path
mkdir -p "$OMME_WINEPREFIX"
touch "$OMME_WINEPREFIX/.omme-initialized-v2"
export OMME_EXE="$tmp_root/OnboardMemoryManager.exe"
touch "$OMME_EXE"
bash "$script_dir/omme-init" --force >/dev/null
assert_log "wineboot <-i>
winetricks <-q> <remove_mono> <dotnet48> <vcrun2022> <win10> <renderer=gdi>
wine <reg> <add> <HKLM\\System\\CurrentControlSet\\Services\\WineBus> </v> <Enable SDL> </t> <REG_DWORD> </d> <0> </f>
wine <reg> <add> <HKLM\\System\\CurrentControlSet\\Services\\WineBus> </v> <DisableHidraw> </t> <REG_DWORD> </d> <0> </f>"

reset_fake_path
if bash "$script_dir/omme-init" >/dev/null 2>"$tmp_root/stderr"; then
  fail "omme-init without exe or OMME_ALLOW_DOWNLOAD should fail"
fi
assert_log ""

reset_fake_path
export OMME_ALLOW_DOWNLOAD=1
bash "$script_dir/omme-init" >/dev/null
assert_log "curl
wineboot <-i>
winetricks <-q> <remove_mono> <dotnet48> <vcrun2022> <win10> <renderer=gdi>
wine <reg> <add> <HKLM\\System\\CurrentControlSet\\Services\\WineBus> </v> <Enable SDL> </t> <REG_DWORD> </d> <0> </f>
wine <reg> <add> <HKLM\\System\\CurrentControlSet\\Services\\WineBus> </v> <DisableHidraw> </t> <REG_DWORD> </d> <0> </f>"

reset_fake_path
export OMME_ALLOW_DOWNLOAD=1
export TEST_SHA256SUM=invalid
if bash "$script_dir/omme-init" >/dev/null 2>"$tmp_root/stderr"; then
  fail "omme-init should reject invalid download hash"
fi
assert_log "curl"

printf 'ok - runtime contract\n'
