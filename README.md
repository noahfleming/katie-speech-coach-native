# Katie Speech Coach Native

Apple-native SwiftUI scaffold for Katie’s premium speech/practice app.

This is the starting point for the real iPhone-first product, separate from the current web prototype in `apps/katie-speech-coach`.

## What this scaffold includes

### How to use the latest Katie native flow
- Start in **Today** to see your active scenario packs and the current mission queue.
- Use the new in-row reminder preview cues to tell whether a pack owns the next reminder, another pack currently owns it, or the pack still needs its first saved rep before Katie can pin a real reminder line.
- Go to **Practice** to record or retake a speaking proof.
- Use **Progress** and **Review** to compare earlier vs latest proof, replay clips when available, and jump back into Practice or Journey-style follow-through.
- Use **Coach** for trust/settings surfaces and reminder ownership clarity.


- SwiftUI app structure for iOS 17+
- XcodeGen project spec (`project.yml`) so the repo can generate a clean `.xcodeproj`
- App shell with a tighter 4-surface core navigation: Today, Practice, Progress, Coach
- Stubbed first-run and premium practice flow:
  - Onboarding
  - Today / Mission
  - Practice / Record
  - Progress
  - Review / Retake handoff from Practice
  - Coach / Trust
- Shared design tokens, simple models, and a root view model
- App-Store-aware placeholders for microphone permission, privacy messaging, offline states, and premium boundaries

## Why a separate native app

The existing web prototype has validated the product loop. This native scaffold gives Katie a path toward:

- better audio capture and playback ergonomics
- real local notifications / reminders
- stronger premium polish and transitions
- App Store-ready privacy, permissions, and entitlement handling
- future StoreKit, sync, and clinician-grade trust surfaces

## Generate the Xcode project

If `xcodegen` is installed:

```bash
cd /Users/liq/.openclaw/workspace/apps/katie-speech-coach-native
xcodegen generate
open KatieSpeechCoachNative.xcodeproj
```

If `xcodegen` is not installed yet:

```bash
brew install xcodegen
```

## First implementation priorities

1. Lock a shared native scenario-pack model that clearly spans interviews, meetings, presentations, and customer moments
2. Replace stub practice recording with `AVAudioRecorder` / `AVAudioSession`
3. Add local notifications for reminder continuity
4. Persist sessions locally with SwiftData
5. Add StoreKit 2 paywall + entitlement model
6. Add polished motion, haptics, and premium transitions

## Current status

This is now a real working Swift/SwiftUI app, not just a scaffold. The project is generated in-repo, current native builds succeed, and recent shipped passes include reminder-preview continuity cues in Today rows plus shared design-system chip/capsule styles that are reused cleanly across Today and Progress. The Today queue now also exposes each pack’s existing overflow actions directly, so proof/compare/journey/reminder/replay shortcuts are reachable from the cross-pack queue without forcing a focus hop first.
