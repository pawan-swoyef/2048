# Engagement Pack — Spec #1: Coins · Daily Streak · Daily Gift

**Date:** 2026-06-08
**App:** 2048 Blocks: Merge Puzzle (`com.number.twofoureight`)
**Goal:** Increase day-over-day retention by rewarding players for coming back.
**Mockups:** `mockups/engagement-aurora.html`, `mockups/engagement-all-themes.html`

## Scope

This is the **first** of four planned increments. It delivers the core
retention loop and the economy foundation the later increments build on.

**In scope (this spec):**
- A local **coins** balance (currency).
- A **daily streak** (consecutive days played) with milestones and a freeze.
- A **daily gift** with a 7-day reward calendar.
- UI: coin pill, streak pill, gift chest, gift-claim dialog, streak sheet, coin toast — themed to all 7 themes.

**Out of scope (later specs):**
- Spec #2: spending coins (unlock themes / buy undos).
- Spec #3: achievements / badges.
- Spec #4: daily challenge.

**Non-goals:** No backend, no account, no ads. Everything is local
(SharedPreferences), matching the app's current persistence.

## Architecture

Keep the **logic pure and testable**, separate from storage and UI.

```
lib/game/
  reward_schedule.dart      # pure: reward tables (coins per gift day, milestone bonuses)
  daily_engagement.dart     # pure: rollover logic (dates in → new state + events out)
  progress_store.dart       # IO: load/save coins/streak/gift state via SharedPreferences
lib/ui/engagement/
  coin_pill.dart            # coin balance chip (gold, theme-constant)
  streak_pill.dart          # flame + day count chip
  daily_gift_dialog.dart    # claim popup with 7-day calendar
  streak_sheet.dart         # streak details + milestones + freeze
  reward_toast.dart         # "+60 coins" toast
```

- `daily_engagement.dart` contains **no Flutter and no IO**. It takes the
  stored state plus an injected `today` date and returns the new state plus
  which events fired (streak incremented, streak reset, freeze used, gift
  unlocked). This is the unit-tested core.
- `progress_store.dart` is a thin wrapper over `SharedPreferences`, mirroring
  the existing `ScoreStore` pattern.
- UI widgets read the current `GameTheme` (via the existing theme controller)
  so colors match the active theme. **Coins (gold) and the flame (fire) are
  constant across themes** — brand/currency elements.

### Data model (SharedPreferences keys)

| Key | Type | Default | Meaning |
|---|---|---|---|
| `coins` | int | 0 | Current coin balance |
| `streak_current` | int | 0 | Consecutive days played |
| `streak_longest` | int | 0 | Best streak ever |
| `last_active_date` | String | "" | Last local date counted (`yyyy-MM-dd`) |
| `gift_claimed_date` | String | "" | Local date the gift was last claimed |
| `streak_freezes` | int | 1 | Freezes held (max 1) |

## Daily rollover logic (`daily_engagement.dart`)

Runs once when the app opens. Inputs: stored state + `today` (local date).
Compute `diff = today - last_active_date` in whole days.

- **First launch** (`last_active_date` empty): `streak_current = 1`.
- **diff == 0**: same day — no streak change.
- **diff == 1**: consecutive — `streak_current += 1`.
- **diff == 2 and `streak_freezes > 0`**: missed exactly one day — consume a
  freeze, `streak_freezes -= 1`, `streak_current += 1` (streak saved).
- **otherwise** (diff >= 2, no freeze, or diff > 2): **reset** — `streak_current = 1`.

Then:
- `streak_longest = max(streak_longest, streak_current)`.
- `last_active_date = today`.
- **Gift is claimable** whenever `gift_claimed_date != today`.
- **Freeze refill:** when `streak_current` crosses a multiple of 7 (i.e. a new
  7-day cycle completes), set `streak_freezes = 1` (cap 1).

### Gift reward calendar

The 7-day calendar position = `((streak_current - 1) % 7) + 1`. The cycle
repeats every 7 days; the player always sees a 7-day calendar.

| Gift day | Coins |
|---|---|
| 1 | 10 |
| 2 | 20 |
| 3 | 30 |
| 4 | 40 |
| 5 | 60 |
| 6 | 80 |
| 7 | 150 |

> Note: the mockup shows a "THEME" reward on Day 7. Granting a premium theme as
> a reward is **deferred to Spec #2**, when coins can actually buy/unlock themes
> — so we don't cannibalize the Premium purchase before the shop exists. For
> Spec #1, Day 7 pays 150 coins.

### Streak milestone bonuses

A coin bonus awarded on the rollover where `streak_current` **becomes exactly**
a milestone value (on top of that day's gift). Because the streak can reset and
climb again, the same milestone can pay out again on a future climb — but never
twice for the same continuous streak.

| Streak day | Bonus coins |
|---|---|
| 3 | +30 |
| 7 | +70 |
| 14 | +150 |
| 30 | +500 |

## UI flow

1. **App open** → run rollover → persist new state.
2. If the gift is claimable, the **chest on the home header glows** with a red
   "ready" dot. (No forced auto-popup; tapping the chest opens the dialog. This
   is gentler and testable. Auto-popup can be a setting later.)
3. **Daily gift dialog**: shows today's reward, the 7-day calendar (past days
   ✓, today highlighted, future dimmed), and a **Claim** button.
4. **Claim** → `coins += reward (+ any milestone bonus)`, set
   `gift_claimed_date = today`, persist, show **coin toast**, chest dims to a
   "Next gift in HHh MMm" countdown.
5. **Streak pill** in the header opens the **streak sheet** (flame, current/best,
   milestone track, freeze status).

All five widgets are themed via the current `GameTheme`.

## Error handling & edge cases

- **Same-day reopen:** rollover is idempotent (diff == 0 changes nothing; gift
  already claimed → not claimable).
- **Clock tampering:** a user can move the device clock forward to farm gifts.
  Accepted limitation for a casual offline game; no server to validate against.
  We will **not** punish backward clock moves (treat negative diff as diff 0).
- **Corrupt/missing prefs:** every read falls back to its default.
- **Longest streak** never decreases.

## Testing

TDD on the pure core:

- `daily_engagement_test.dart`: first launch; same day; consecutive; one-miss
  with freeze; one-miss without freeze; multi-day miss; negative diff (clock
  back); longest-streak update; freeze refill at day 7/14; cycle-day calc.
- `reward_schedule_test.dart`: coins per gift day 1–7; milestone bonus mapping.
- `progress_store_test.dart`: round-trip save/load with defaults (using
  `SharedPreferences.setMockInitialValues`).
- Widget smoke tests (optional): gift dialog renders calendar; claim invokes
  callback.

## Rollout

Ship behind no flag — it's additive and local. Bump `pubspec.yaml` version
(e.g. `1.0.1+2`) for the release that includes it.
