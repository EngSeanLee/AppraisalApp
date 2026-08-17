# Dictation Cleanup Worker

A small Cloudflare Worker that sits between the iOS app and Claude: the
app sends a raw speech-to-text transcript here, this calls Claude Haiku
4.5 to clean it into a well-formed paragraph, and sends the result back.

It exists for one reason: **the Anthropic API key can't go in the iOS
app.** A compiled app's strings are trivially extractable, so an embedded
key is a leaked key — billed to your account, with no way to revoke it
without breaking the app for everyone. This Worker holds the key as a
server-side secret instead.

This means dictation cleanup needs an internet connection (everything
else in the app — export, photos, saved appraisals — stays fully
offline).

## One-time setup

You'll need:
1. **A Cloudflare account** (free tier is plenty for this) — cloudflare.com.
2. **An Anthropic API key** — separate from any Claude Code/Claude.ai
   login. Create one at [console.anthropic.com](https://console.anthropic.com)
   → API Keys. This is a *pay-as-you-go* key: cleanup requests are small
   and use a cheap model, but it does mean real (small) charges land on
   whatever card is on that Anthropic account.
3. **Node.js** installed, to run `npm`/`npx`.

## Deploy

From this `worker/` folder:

```sh
npm install
npx wrangler login          # opens a browser to authorize Cloudflare
npx wrangler secret put ANTHROPIC_API_KEY
# paste the key from console.anthropic.com when prompted

npx wrangler deploy
```

The deploy step prints a URL like:

```
https://jewelry-appraisal-dictation-cleanup.<your-subdomain>.workers.dev
```

Copy that URL, append `/cleanup`, and paste it into
`App/Services/DictationCleanupService.swift`, replacing the
`REPLACE-WITH-YOUR-WORKER-URL` placeholder in the `endpoint` constant near
the top of the file. Then push that change through the usual sideload/CI
flow (see the main README) to get it onto the phone.

## Optional: a shared-secret check

`DictationCleanupService.swift` can send an `X-App-Secret` header, which
this Worker checks against an `APP_SHARED_SECRET` secret if one is set:

```sh
npx wrangler secret put APP_SHARED_SECRET
```

...then set the matching `sharedSecret` constant in
`DictationCleanupService.swift` to the same value.

**Be clear-eyed about what this does and doesn't protect against.** It
raises the bar slightly over a wide-open endpoint, and lets you rotate
access without touching your Anthropic key — but a string embedded in the
app is still extractable from the compiled binary the same way the
Anthropic key itself would be, so this is abuse-resistance, not a real
security boundary. If you skip it, leave both sides unset (the default) —
the Worker just won't check.

## Cost

Anthropic bills per request; Cloudflare Workers' free tier (100,000
requests/day) covers this use case with room to spare. Realistically,
for one appraiser dictating a handful of appraisals a day, the Anthropic
cost here is cents, not dollars — but it's not literally free the way the
rest of the app is.
