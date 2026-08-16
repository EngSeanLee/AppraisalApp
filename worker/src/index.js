import Anthropic from "@anthropic-ai/sdk";

/**
 * Cleans up a raw speech-to-text dictation transcript from the appraisal
 * app into a well-formed paragraph, via Claude Haiku 4.5 — small, fast,
 * and cheap, which is all this needs: "clean up a dictation transcript"
 * is a lightweight text task, not something that benefits from a bigger
 * model.
 *
 * This exists because the Anthropic API key can never live in the iOS
 * app itself (a compiled app's strings are trivially extractable) — this
 * Worker holds the key as a secret and is the only thing that ever talks
 * to Claude directly. See README.md in this folder for how to deploy it.
 */
export default {
  async fetch(request, env) {
    if (request.method !== "POST") {
      return new Response("Expected POST", { status: 405 });
    }

    // Optional, lightweight abuse guard — not a real security boundary
    // (see README.md), but if APP_SHARED_SECRET is set as a Worker
    // secret, require the app to send it back.
    if (env.APP_SHARED_SECRET) {
      const provided = request.headers.get("X-App-Secret");
      if (provided !== env.APP_SHARED_SECRET) {
        return new Response("Unauthorized", { status: 401 });
      }
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return new Response("Invalid JSON body", { status: 400 });
    }

    const transcript = typeof body.transcript === "string" ? body.transcript.trim() : "";
    if (!transcript) {
      return new Response("Missing 'transcript'", { status: 400 });
    }
    // Dictation sessions are short (tap-to-talk, one field at a time) —
    // this is a generous ceiling against an oversized/abusive request,
    // not a real-world limit for how this actually gets used.
    if (transcript.length > 8000) {
      return new Response("Transcript too long", { status: 413 });
    }

    const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });

    let message;
    try {
      message = await client.messages.create({
        model: "claude-haiku-4-5",
        max_tokens: 1024,
        system:
          "You clean up raw speech-to-text transcripts of jewelry appraisal descriptions dictated by a jeweler. Fix run-on sentences, filler words, false starts, and obvious mis-transcriptions of jewelry terms (metals, karats, stone names, grading terms) where context makes the intended word clear. Preserve every number, weight, grade, and factual detail exactly as given — never invent, round, or 'correct' a figure. Output only the cleaned description text, with no preamble, quotation marks, or commentary.",
        messages: [{ role: "user", content: transcript }],
      });
    } catch (error) {
      return new Response(`Claude request failed: ${error.message ?? error}`, { status: 502 });
    }

    const cleaned = message.content.find((block) => block.type === "text")?.text ?? transcript;

    return new Response(JSON.stringify({ cleaned }), {
      headers: { "Content-Type": "application/json" },
    });
  },
};
