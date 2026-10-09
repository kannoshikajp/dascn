---
name: semantic-commits
description: Format git commit messages using semantic commit guidelines with emojis.
---

# Semantic Commits with Emojis

Whenever you commit code to the repository or suggest commit messages to the user, you MUST follow these semantic commit guidelines using emojis.

## Format
`<type>(<optional-scope>): <emoji> <subject>`

## Types and Emojis
*   `feat`: ✨ (New feature)
*   `fix`: 🐛 (Bug fix)
*   `docs`: 📝 (Documentation changes)
*   `style`: 🎨 (Formatting, missing semi-colons, etc.)
*   `refactor`: ♻️ (Code changes that neither fix a bug nor add a feature)
*   `perf`: ⚡️ (Performance improvements)
*   `test`: ✅ (Adding or updating tests)
*   `chore`: 🔧 (Maintenance tasks, build process, dependencies)
*   `ci`: 👷 (CI/CD pipeline changes)
*   `revert`: ⏪️ (Reverting a previous commit)

## Examples
*   `feat(auth): ✨ add Google OAuth login`
*   `fix(cart): 🐛 resolve checkout calculation error`
*   `docs(readme): 📝 update installation steps`
*   `chore(deps): 🔧 upgrade spring boot to 3.x`

Always enforce this standard when generating or executing `git commit`.
