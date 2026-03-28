# Contributing to Med-Guide

Thank you for your interest in contributing! Med-Guide is an open-source project that helps people understand their medical results in plain language.

## How to Contribute

### Reporting Issues

- Use [GitHub Issues](https://github.com/burakcanpolat/med-guide/issues) to report bugs or suggest features
- Include your editor (Zed, Cursor, Claude Code) and OS in bug reports
- For DICOM-related issues, include the modality (CT, MRI, X-ray) and any error output

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Test your changes (see [Testing](#testing) below)
5. Commit with a clear message: `git commit -m "Add: brief description"`
6. Push to your fork: `git push origin feature/your-feature`
7. Open a Pull Request

### Development Setup

```bash
git clone https://github.com/burakcanpolat/med-guide.git
cd med-guide
uv sync
```

This installs all dependencies (pydicom, numpy, Pillow) in an isolated virtual environment.

### Testing

```bash
# Verify imports work
uv run python -c "import scripts.dicom_utils"
uv run python -c "from pathlib import Path; import importlib.util; spec = importlib.util.spec_from_file_location('m', Path('scripts/medgemma_api.py')); mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)"

# Test with sample images (requires Modal deployment)
uv run python scripts/medgemma_api.py test/sample-xrays/normal/normal-xray-1.jpeg
```

## Project Structure

| Directory | Purpose |
|-----------|---------|
| `scripts/` | Python scripts (API client, DICOM utils, Modal deployment) |
| `skills/` | Readable skill files for AI editors |
| `.agents/skills/` | Universal skill format (frontmatter + instructions) |
| `CLAUDE.md` / `AGENTS.md` | Editor instruction files |
| `.cursor/rules/` | Cursor-specific rules |

## Areas for Contribution

### Adding Language Support

Med-Guide currently supports English and Turkish. To add a new language:

1. Add the language option to the language selection prompt in `CLAUDE.md` (and sync to `AGENTS.md`, `.cursor/rules/medgemma.mdc`)
2. Add bilingual table entries for report section headers in `CLAUDE.md` and `skills/radiology-skill.md`
3. Add the disclaimer translation to all files that contain the disclaimer table
4. Add the translated setup wizard messages in `.agents/skills/medgemma-setup/SKILL.md`

### Improving DICOM Support

- Adding new CT window presets for body regions (see `_CT_WINDOW_PRESETS` in `scripts/dicom_utils.py`)
- Supporting additional transfer syntaxes
- Improving metadata extraction

### Adding New Skills

Skills follow a standard format. See existing skills in `.agents/skills/` for the template:

```yaml
---
name: skill-name
description: When to use this skill
license: MIT
metadata:
  author: your-name
  version: "1.0"
  language: en
---

# Skill Title

Instructions for the AI assistant...
```

Place skill files in both:
- `.agents/skills/your-skill/SKILL.md` (universal format)
- `skills/your-skill.md` (readable copy)

### Documentation

- Fixing typos or unclear instructions
- Adding examples for different medical scenarios
- Translating documentation

## Guidelines

### Code Style

- Python: PEP 604 type hints (`float | None`, not `Union[float, None]`), no `from __future__ import annotations`
- All CLI examples use `uv run python scripts/...`
- No `pip install` references — use `uv sync` for dependencies, `uv tool install` for CLI tools

### Documentation Consistency

This project maintains identical content across multiple editor instruction files. When editing documentation:

- `CLAUDE.md`, `AGENTS.md`, and `.cursor/rules/medgemma.mdc` must stay in sync (`.mdc` has YAML frontmatter)
- All 7 rules must be identical across all skill files
- Disclaimer text must match in all files
- CLI examples must use `uv run python scripts/medgemma_api.py` everywhere

### Commit Messages

Use clear, descriptive messages:
- `Add: new feature description`
- `Fix: bug description`
- `Update: what changed and why`

## Code of Conduct

Be respectful and constructive. This project helps people understand their health — treat contributions with the seriousness that deserves.

## Questions?

Open a [GitHub Issue](https://github.com/burakcanpolat/med-guide/issues) or start a [Discussion](https://github.com/burakcanpolat/med-guide/discussions).

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
