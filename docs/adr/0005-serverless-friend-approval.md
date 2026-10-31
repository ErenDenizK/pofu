# 0005. Serverless friend approval

- **Status:** Accepted
- **Date:** 2026-10-31

## Context

The top rung of the friction ladder lets a trusted friend approve an unlock
after the user's daily budget is exhausted. Apple offers no adult-to-adult
mechanism for this; the system "Ask for More Time" flow works only for child
accounts in Family Sharing. Running our own backend adds cost, operations, and
KVKK/GDPR obligations before we know whether the feature is loved.

## Options considered

1. **Own backend** (Supabase, Firebase). Real-time push, rich social features,
   and cross-platform reach. Ongoing cost and compliance burden from day one.
2. **CloudKit.** Apple-hosted, free at our scale, push via subscriptions,
   private by default. iOS-only, and sharing semantics are complex.
3. **Serverless cryptographic approval.** Two friends pair once. Approvals
   are signed codes exchanged over any messenger. No infrastructure.

## Decision

Ship friend approval with **option 3**, and build later social features
(shared streaks, leagues) on **CloudKit** in a future ADR.

Protocol:

1. **Pairing (once):** friend A shows a QR code or sends an invite link
   containing a randomly generated 256-bit secret. Friend B's app stores it in
   the Keychain. Both now share a key.
2. **Request:** when B needs approval, B's app creates a challenge (nonce,
   timestamp, requested minutes) and shares it as a link through the system
   share sheet (iMessage, WhatsApp, Telegram).
3. **Approve:** A taps the link. A's app shows who is asking, for how long,
   and B's recent context. If A approves, the app returns a grant: an
   HMAC-SHA256 of the challenge, delivered as a link back to B, plus a
   six-digit code fallback for manual entry.
4. **Redeem:** B's app verifies the grant against the stored secret and the
   challenge's freshness window (for example 15 minutes), then unlocks.

Links use HTTPS universal links on a project domain, because messengers such
as WhatsApp do not make custom URL schemes tappable. The six-digit code
remains as a universal fallback.

Threat model: the adversary is the user's own impulse, not a sophisticated
attacker. The design prevents casual self-approval and replay; it does not try
to resist a user who extracts Keychain secrets from their own jailbroken
device.

## Consequences

- Zero servers, zero personal data stored, zero running cost.
- Works across every messenger the user already uses.
- Requires the friend to have the app installed, which is also a natural
  invitation loop.
- Universal links require a domain and the Associated Domains capability
  (paid membership).
