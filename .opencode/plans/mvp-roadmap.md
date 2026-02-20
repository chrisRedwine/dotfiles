# MVP Roadmap — Iterative Dotfiles Bootstrap

**Status**: MVP-3 ✅ COMPLETE — Ready for MVP-4  
**Approach**: Small commits, pause for review between steps, test on iMac then MacBook Pro

---

## Progress

- [x] **MVP-1**: Hello-world chezmoi bootstrap (tested on iMac)
- [x] **MVP-2**: `.gitconfig` with user settings (tested on both machines)
- [x] **MVP-3**: Brew package installation (declarative package lists)
- [ ] **MVP-4**: Minimal inventory collection
- [ ] **MVP-5**: Real dotfiles migrated

---

## MVP-1: "Can chezmoi run at all?"

**Goal**: One command on a fresh machine installs chezmoi and applies a trivial template.

### Deliverables

```
dotfiles/
├── README.md              # One-liner install command
├── bootstrap.sh           # Entrypoint: installs chezmoi + applies
└── home/                  # chezmoi source directory
    └── dot_hello.tmpl     # Hello world template
```

### Files

**bootstrap.sh**:
```bash
#!/bin/bash
set -euo pipefail

echo "==> Installing chezmoi..."
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"

export PATH="$HOME/.local/bin:$PATH"

echo "==> Initializing dotfiles..."
chezmoi init --apply https://github.com/chrisRedwine/dotfiles.git

echo "==> Done! Check ~/.hello"
cat ~/.hello
```

**home/dot_hello.tmpl**:
```
Hello from chezmoi on {{ .chezmoi.os }}!
Hostname: {{ .chezmoi.hostname }}
```

**README.md**:
```markdown
# dotfiles

Personal macOS dotfiles managed with chezmoi.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/chrisRedwine/dotfiles/main/bootstrap.sh | bash
```

## Machines

- iMac (personal)
- MacBook Pro (work)

See `.opencode/plans/` for implementation details.
```

### Test Procedure

1. Run on iMac: `curl -fsSL ... | bash`
2. Verify `~/.hello` contains "Hello from chezmoi on darwin!" and correct hostname
3. Push to GitHub
4. On MacBook Pro: run same command, verify hostname is different

---

## MVP-2: "Share one real config file"

**Goal**: Manage `.gitconfig` with per-machine email.

### Deliverables

**home/dot_gitconfig.tmpl**:
```gitconfig
[user]
    name = Chris Redwine
    email = {{ if eq .chezmoi.hostname "work-macbook-pro" }}work@company.com{{ else }}personal@gmail.com{{ end }}

[core]
    editor = vim

[init]
    defaultBranch = main
```

> **Note**: Replace hostnames with actual values from `scutil --get ComputerName` or `hostname -s`.

### Test Procedure

1. Add template to `home/dot_gitconfig.tmpl`
2. On iMac: `chezmoi apply` → verify personal email
3. On MacBook Pro: `chezmoi apply` → verify work email
4. Edit on one machine, push, pull on other, verify sync

---

## MVP-3: "Install one package via brew"

**Goal**: Integrate brew with chezmoi's `run_onchange_` pattern.

### Deliverables

**home/.chezmoidata/packages.yaml**:
```yaml
packages:
  darwin:
    formulae:
      - git
      - vim
    casks: []
```

**home/run_onchange_darwin-install-packages.sh.tmpl**:
```bash
#!/bin/bash
set -euo pipefail

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo "==> Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install packages from chezmoidata
echo "==> Installing packages..."
{{ range .packages.darwin.formulae -}}
brew install {{ . }}
{{ end -}}
{{ range .packages.darwin.casks -}}
brew install --cask {{ . }}
{{ end -}}

echo "==> Packages installed."
```

### Test Procedure

1. Add packages.yaml and script template
2. Add a test package (e.g., `tree`)
3. `chezmoi apply` → verify package installs
4. Re-run `chezmoi apply` → verify idempotent (no re-install)
5. Add another package to yaml, re-apply → verify new package installs

---

## MVP-4: "Minimal inventory collection"

**Goal**: Create inventory tooling framework, collect just brew + dotfiles list.

### Deliverables

**inventory/macos/collect.sh**:
```bash
#!/bin/bash
set -euo pipefail

OUTPUT_DIR="inventory/output/$(date +%Y%m%d)-$(hostname -s)"
mkdir -p "$OUTPUT_DIR"

echo "==> Collecting Homebrew state..."
brew bundle dump --file="$OUTPUT_DIR/Brewfile" --force

echo "==> Listing dotfiles..."
ls -la ~ | grep "^\." > "$OUTPUT_DIR/dotfiles-list.txt"

echo "==> Inventory collected to $OUTPUT_DIR"
```

**inventory/macos/redact.sh** (basic auto-redaction):
```bash
#!/bin/bash
set -euo pipefail

INPUT_DIR="${1:-inventory/output}"

echo "==> Redacting sensitive data..."
# Auto-redact obvious patterns (emails, UUIDs, etc.)
find "$INPUT_DIR" -type f -exec sed -i '' \
    -e 's/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/[REDACTED_EMAIL]/g' \
    -e 's/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[REDACTED_UUID]/g' \
    {} +

echo "==> Redaction complete. Review manually before committing."
```

**inventory/output/.gitignore**:
```
*
!.gitignore
```

### Test Procedure

1. Run `inventory/macos/collect.sh` on iMac
2. Review output in `inventory/output/`
3. Run `inventory/macos/redact.sh`
4. Verify no sensitive data in redacted output
5. Verify `inventory/output/` is gitignored

---

## MVP-5: "Apply real configs"

**Goal**: Expand to actual dotfiles you use daily.

### Deliverables

**Migrate from inventory**:
- `.zshrc` (aliases, functions, path setup)
- `.vimrc` or `.config/nvim/init.vim`
- `.ssh/config` (structure, not keys)
- Custom scripts from `~/bin/`

**Update docs**:
- `docs/decisions.md` — Toolchain choices
- `docs/update-workflow.md` — Bidirectional sync process

### Test Procedure

1. Inventory current machine to identify all dotfiles
2. Migrate high-priority configs to `home/`
3. Test on iMac: `chezmoi apply`, verify configs work
4. Push, test on MacBook Pro
5. Iterate: make change on one machine, sync to other

---

## Future Work (Post-MVP)

### 1Password Integration

Research and implement:

```bash
# Option: Template calling op CLI at apply-time
echo "export API_KEY={{ onepasswordRead "op://vault/item/field" }}" >> ~/.zshrc
```

Or use chezmoi's built-in 1Password support:
```bash
chezmoi init --onepassword
```

### macOS Defaults

- Collect and apply system preferences
- Dock, trackpad, keyboard, display settings

### Full Inventory

- Exhaustive scan of home directory
- Application preferences (plist files)
- Environment variables (names only)
- Dev toolchains detection

### CI/CD

- GitHub Actions for pre-commit (Linux)
- GitHub Actions for release validation (macOS runner)

---

## Workflow Notes

### Commit Strategy

1. **Pause after each file** — review before staging
2. **One logical change per commit** — easy to revert
3. **Test before commit** — verify it works on current machine
4. **Push frequently** — sync between machines

### Between-Machine Sync

```bash
# Machine A (iMac)
# Edit something
chezmoi edit ~/.zshrc
chezmoi diff
chezmoi apply
chezmoi cd
git add .
git commit -m "Add ll alias to zshrc"
git push

# Machine B (MacBook Pro)
chezmoi update  # pulls and applies
chezmoi diff    # see what changed
```

### Testing Checklist (Each MVP)

- [ ] Works on iMac (personal)
- [ ] Works on MacBook Pro (work)
- [ ] Idempotent (re-running doesn't break anything)
- [ ] No secrets committed
- [ ] Documentation updated

---

## Ready to Start?

Begin with **MVP-1**. Review the deliverables above, then tell the Build agent to implement.
