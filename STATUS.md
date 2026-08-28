# HermesMini (fork of hermes-conduit) — status

Chris asked for his own customized iOS client for Hermes Agent (A-C: rebrand,
custom routing/config, feature changes). Repo: github.com/ztersmarketing/hermes-conduit.

## Done (2026-08-28)
- Forked kaishi00/hermes-conduit -> ztersmarketing/hermes-conduit
- Local clone: ~/Hermes/projects/hermes-conduit, branch `chris/custom`, pushed
- xcodegen v2.46.0 + mas installed (brew)
- Rebranded baseline Conduit -> **HermesMini** (WORKING NAME, changeable):
  - dirs git mv'd Conduit* -> HermesMini*
  - bundle id com.milim.relay -> com.cmm.hermesmini, bundleIdPrefix com.cmm
  - logger subsystems com.milim.* -> com.cmm.*
  - signing flipped to Automatic (dropped upstream team U2TH557QA8 + App Store profiles)
  - Xcode project regenerates clean: HermesMini.xcodeproj via `xcodegen generate`
  - committed + pushed to chris/custom
- scripts/rebrand.sh = idempotent re-namer, so final name is one command:
  `./scripts/rebrand.sh <NewName> <prefix> HermesMini`

## Blocked on Chris
1. **Xcode install** — 11GB, App Store opened to Xcode page; needs his single
   click (mas install needs sudo, not configured). Gate for all builds.
2. **Final app name** — HermesMini is a placeholder. Re-run rebrand.sh when chosen.
3. **Signing decision** — free Apple ID (7-day cert, fine for tinkering) vs
   paid dev account (1yr, TestFlight). Needed to install on his iPhone.
4. **Feature list** — he said "A-C + customizations", specifics not yet named.
5. **Own push relay?** — app already supports custom relay URL in-app
   (Settings > Notifications > Push relay, key conduit.relayURL). Default is
   push.milim.dev. Self-hosted relay = separate server deploy if he wants it.

## Facts learned about hermes-conduit
- Pure SwiftUI, iOS 17+, xcodegen-generated (project.yml single source).
- ~50k LOC / 90 swift files main app + tests. Key files: Services/HermesClient.swift
  (WS to /api/ws), Services/AppState.swift (+8600 lines), Services/PushNotificationService.swift.
- Relay URL is already user-configurable; no code change needed for own relay.
- Privacy: MIT, connects only to own Hermes dashboard at :9119.

## Next
- When Xcode done: xcodegen generate && xcodebuild for device/simulator to
  smoke-test, then install to iPhone.
- Rebrand script needs a small fix if re-run: it uses python replace on
  project.yml; finished version wrote project.yml by hand. Script works for
  main rename but target keys needed manual patch — verify before trusting.
