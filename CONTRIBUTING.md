# Contributing to Simplify11

Thanks for your interest in contributing to Simplify11! This guide will help you get started.

## Getting Started

1. **Fork** the repository on GitHub
2. **Clone** your fork locally:
   ```
   git clone https://github.com/YOUR-USERNAME/simplify11.git
   ```
3. **Create a branch** for your changes:
   ```
   git checkout -b feature/your-feature-name
   ```

## Development Setup

Simplify11 is a PowerShell-based project. You'll need:

- Windows 11 (for testing)
- PowerShell 5.1+ (included with Windows)
- A code editor (VS Code recommended with the PowerShell extension)

### Project Structure

```
simplify11/
├── simplify11.ps1          # Main entry point
├── version.json            # Version metadata
├── scripts/                # Core scripts (admin launch, common utilities)
├── modules/
│   ├── system/             # System tweaks
│   ├── security/           # Security tools
│   ├── drivers/            # Driver installation
│   ├── tools/              # Third-party tool integrations
│   ├── unigetui/           # Package manager integration
│   └── windots/            # Customization and ricing
├── docs/                   # Documentation and guides
└── media/                  # Icons, logos, assets
```

## Coding Guidelines

### PowerShell Conventions

- Use **approved PowerShell verbs** for function names (`Get-`, `Set-`, `New-`, `Remove-`, `Invoke-`, etc.)
  - Run `Get-Verb` in PowerShell to see the full list
- Use **4-space indentation** (no tabs)
- Include error handling (`try/catch`) for any external downloads or network operations
- Add descriptive `-Message` parameters to `Set-RegistryValue` calls

### Adding New Tweaks

1. Add your tweak function to the appropriate file in `modules/`
2. Include source links as comments above registry modifications
3. Test thoroughly on a clean Windows 11 installation
4. Document what the tweak does and why

### Commit Messages

Write clear, concise commit messages:
- `fix: correct menu navigation for Security option`
- `feat: add selective tweak application`
- `docs: update README with compatibility table`

## Testing

Before submitting a PR:

1. Test your changes on a **clean Windows 11 VM** (recommended)
2. Create a **System Restore Point** before testing tweaks
3. Verify the menu navigation works correctly
4. Check that all function names use approved PowerShell verbs
5. Ensure no tabs are mixed with spaces

## Submitting a Pull Request

1. Push your branch to your fork
2. Open a Pull Request against the `main` branch
3. Describe what your changes do and why
4. Reference any related issues (e.g., "Fixes #42")

## Reporting Issues

Use the issue templates provided:
- **Bug Report** — for something that isn't working correctly
- **Feature Request** — for suggesting new features or improvements

## Code of Conduct

Be respectful and constructive. We're all here to make Windows 11 better.
