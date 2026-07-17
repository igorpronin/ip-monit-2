# IPMonit — notes for Claude

macOS menu bar utility (Swift Package, no Xcode project). `./build-app.sh` builds the public variant, `./build-app.sh -dev` builds the owner's local variant (extra About info via `DEV_BUILD` compile flag). The copy installed in `/Applications` must always be the `-dev` build.

## README files

`README.md` (English) and `README.ru.md` (Russian) are mirrors of each other. Any change to one MUST be applied to the other in the same commit. Both keep the language-switcher links (`**English** | [Русский](README.ru.md)` / `[English](README.md) | **Русский**`) at the top — do not remove them.

## Rebuilding the public build (dist/IPMonit.zip)

The prebuilt app is committed to the repo. To keep the repository small, old zip versions must NOT accumulate in git history. Whenever you rebuild and re-publish `dist/IPMonit.zip`:

1. Build and pack:
   ```sh
   ./build-app.sh
   ditto -c -k --keepParent build/IPMonit.app dist/IPMonit.zip
   ```
2. Verify the binary inside the zip contains no dev-only strings (`strings -a ... | grep -iE 'claude|dev build|proninigor'` must find nothing).
3. Remove the old zip from ALL history, then commit the new zip as its own commit:
   ```sh
   FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --index-filter \
     'git rm --cached --ignore-unmatch -q dist/IPMonit.zip' --prune-empty HEAD
   # filter-branch resets the working tree — recreate the zip, then:
   git add dist/IPMonit.zip && git commit -m "Add prebuilt public app (dist/IPMonit.zip)"
   rm -rf .git/refs/original
   git reflog expire --expire=now --all
   git gc --prune=now
   ```
4. This rewrites history: once a remote exists, push with `git push --force-with-lease`.
