---
name: open-chrome-profile
description: Open a URL in a specific Google Chrome profile on macOS from the terminal with the open command. Use when a person asks to open a page "in my work/personal Chrome", "in the Chrome profile for <email>", or in a named Chrome profile. Use the terminal command, not browser automation or a Chrome extension.
---

# Open Chrome in a specific profile (macOS)

One command opens a URL in the Chrome profile that is signed in with a given
email address:

```sh
open -na "Google Chrome" --args --profile-email=user@example.com "https://example.com/"
```

Replace `user@example.com` with the profile's Google account email and the URL
with the page to open. The examples in this skill use reserved values. Do not
write a person's real email into repositories, docs, or scripts.

## Why each part matters

- `-a "Google Chrome"`: the app to open.
- `-n`: required. Without it, macOS hands the request to the running Chrome and
  **drops everything after `--args`**. The page then opens in the last active
  profile, which is the usual confusing result.
- `--args`: everything after it goes to Chrome, not to `open`.
- `--profile-email=<email>`: Chrome picks the profile signed in with that email.
- The URL comes last.

`open -a "Google Chrome" "https://example.com/"` (no `-n`, no profile flag)
always uses the last active profile.

## Fallback: profile directory

If the profile is not signed in to a Google account, use its directory name:

```sh
open -na "Google Chrome" --args --profile-directory="Profile 1" "https://example.com/"
```

The first profile is `Default`; later ones are `Profile 1`, `Profile 2`, and so
on. To find the name, open `chrome://version` in the wanted profile and read the
last part of **Profile Path**.

## Workflow

1. Get the profile email (or directory name) and the URL from the person.
   Do not guess an email from other context.
2. Run the command with the helper or directly:

   ```sh
   scripts/open-chrome-profile.sh user@example.com "https://example.com/"
   scripts/open-chrome-profile.sh "Profile 1" "https://example.com/"
   ```

   An argument with `@` is used as `--profile-email`; anything else is used as
   `--profile-directory`.
3. Tell the person the command you ran. Exit status 0 means macOS accepted the
   request; it does not prove which window received it. Ask the person to check
   the profile avatar if it matters.

## Do not

- Do not use browser automation, a Chrome extension, or CDP only to open a page.
- Do not read Chrome's `Local State` or profile folders to find profiles. macOS
  privacy controls often block the terminal (`Operation not permitted`); use
  `--profile-email` or ask for the `chrome://version` profile path instead.
- Do not commit real email addresses. Use `user@example.com` in examples.

## Troubleshooting

- Page opens in the wrong profile: `-n` is missing, or the email is not the
  account signed in to any profile (check the avatar menu in Chrome).
- `Unable to find application named 'Google Chrome'`: Chrome is not installed in
  `/Applications`, or the channel is different (for example `Google Chrome Beta`).
