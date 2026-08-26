# AGENTS.md

## 1. Project Definition

SetTimer is a **desktop application** for Windows and Linux.

It is not a website, web application, browser application, or server product.

The primary product goal is to provide a simple and natural interval-training timer with an interaction style inspired by iPhone system applications.

Typical session flow:

```text
Work
→ Rest
→ Work
→ Rest
→ ...
→ Complete
```

The application should feel like a polished native desktop utility rather than a web page running inside a desktop shell.

---

## 2. Platform Scope

Supported platforms:

```text
Windows
Linux
```

Not currently in scope:

```text
Web
iOS
Android
macOS
Browser extension
Server deployment
```

Do not introduce architecture for unsupported platforms unless a concrete requirement is added.

---

## 3. Desktop-First Rule

SetTimer must remain a desktop GUI application.

Do not turn the project into:

- a React website
- a Vue website
- an Electron application
- a browser-hosted application
- a client/server application
- a local HTTP service with a browser UI

Do not introduce:

```text
HTML
CSS
React
Vue
Next.js
Vite
Electron
browser routing
REST APIs
frontend/backend separation
```

unless the project direction is explicitly changed.

The application should launch directly as a desktop executable.

---

## 4. Preferred UI Architecture

The preferred UI stack is:

```text
Qt 6
+
Qt Quick / QML
```

A Python implementation may use:

```text
PySide6 + QML
```

A C++ implementation may use:

```text
Qt 6 + QML
```

QML is preferred over traditional widget-heavy UI when implementing:

- smooth transitions
- animated controls
- gesture-like interactions
- large timer displays
- iPhone-inspired visual behavior
- responsive layouts

The exact implementation language may evolve, but the application must remain a real desktop GUI.

---

## 5. Design Direction

The UI should be inspired by the interaction quality of iPhone system applications.

This means:

- visually calm
- large readable numbers
- clear hierarchy
- minimal controls
- smooth short animations
- obvious primary actions
- consistent spacing
- natural state transitions
- immediate interaction feedback

It does **not** mean copying Apple assets or reproducing iOS pixel-for-pixel.

The goal is:

> iPhone-like interaction quality on a Windows/Linux desktop application.

---

## 6. Product Priorities

When engineering choices conflict, use this priority order:

1. Timer correctness
2. Interaction clarity
3. Application reliability
4. Desktop usability
5. Cross-platform behavior
6. Testability
7. Simplicity
8. Performance
9. Abstraction
10. Future extensibility

Do not sacrifice timer correctness for animation or visual polish.

---

# Architecture

## 7. Layering

The application should use clear boundaries:

```text
QML UI
   ↓
Application Controller / ViewModel
   ↓
Timer Domain Engine
   ↓
Clock / Settings / Audio abstractions
   ↓
Desktop platform implementations
```

Recommended responsibilities:

### QML UI

Responsible for:

- visual rendering
- animation
- user input
- focus
- keyboard interaction
- displaying timer state

Not responsible for timer calculations.

### Application / ViewModel

Responsible for:

- receiving UI commands
- exposing observable application state
- coordinating domain services
- mapping domain events to UI-friendly state

### Timer Engine

Responsible for:

- session state
- phase transitions
- work/rest sequencing
- pause/resume semantics
- countdown thresholds
- completion events

### Platform Services

Responsible for:

- monotonic clock
- text-to-speech
- audio playback
- settings storage
- desktop notifications
- platform integration

---

## 8. UI and Domain Must Be Separate

QML files must not implement timer business rules.

Forbidden:

```text
QML Timer:
    remainingSeconds -= 1

if remainingSeconds == 0:
    currentSet += 1
```

The UI must receive authoritative state from the application/domain layer.

QML timers may trigger repaint/update requests, but must not be the source of elapsed-time truth.

---

# Timer Correctness

## 9. Monotonic Clock Is Mandatory

Elapsed time must use a monotonic clock.

Conceptually:

```text
deadline = monotonic_now + duration
remaining = deadline - monotonic_now
```

Never calculate elapsed timer duration from system wall-clock time.

Do not use:

```text
Date.now()
system clock timestamp
local datetime
timezone-aware datetime
```

as the authoritative elapsed-time source.

Wall-clock time may change because of:

- manual clock changes
- NTP synchronization
- timezone changes
- daylight-saving transitions

A countdown timer must remain correct despite those changes.

---

## 10. UI Refresh Is Not Time

Forbidden implementation:

```text
every 1000 ms:
    remaining -= 1
```

The UI refresh interval is only a rendering mechanism.

Correct model:

```text
remaining = deadline - monotonic_now
```

If the UI freezes for three seconds and then resumes, the timer must immediately display the correct remaining time.

---

## 11. Clock Abstraction

Core timer logic should depend on a clock abstraction.

Example:

```text
Clock
└── now_monotonic()
```

Production implementation:

```text
SystemMonotonicClock
```

Test implementation:

```text
FakeClock
```

This makes timer tests deterministic and fast.

---

## 12. Pause / Resume

Pause must preserve the exact remaining duration.

Resume must continue from the preserved duration.

Repeated pause/resume operations must not accumulate meaningful drift.

Example:

```text
Work: 60.0s
after 17.4s → pause
remaining: 42.6s

resume
deadline = current_monotonic_time + 42.6s
```

Do not reconstruct remaining time from UI labels.

---

## 13. Phase Completion Must Be Idempotent

A phase may complete only once.

Multiple update callbacks around the same deadline must not cause duplicate transitions.

Forbidden result:

```text
WORK completed
→ REST
→ REST again
→ current_set increments twice
```

Timer transition logic must guard against duplicate completion handling.

---

# State Machine

## 14. Explicit States

Timer state must be modeled explicitly.

Recommended states:

```text
IDLE
PREPARING
WORK
REST
PAUSED
COMPLETED
```

Avoid combinations such as:

```text
isRunning
isPaused
isResting
isFinished
```

because contradictory states become possible.

---

## 15. Legal State Transitions

Typical transitions:

```text
IDLE → PREPARING
PREPARING → WORK

WORK → REST
WORK → PAUSED
WORK → COMPLETED

REST → WORK
REST → PAUSED
REST → COMPLETED

PAUSED → WORK
PAUSED → REST

COMPLETED → IDLE
```

If pause needs to preserve the previous phase, store it explicitly.

Illegal transitions should fail visibly in development rather than silently changing state.

---

## 16. Domain Objects

Core concepts should have explicit types.

Recommended examples:

```text
SessionConfig
TimerState
TimerPhase
SessionProgress
TimerEvent
CountdownThreshold
```

Avoid unstructured dictionaries and magic strings.

Prefer:

```text
TimerPhase.WORK
```

over:

```text
"work"
```

where practical.

---

# Session Model

## 17. Session Configuration

Persistent/user-configurable session values may include:

```text
work_duration
rest_duration
set_count
preparation_duration
speech_enabled
sound_enabled
countdown_enabled
countdown_thresholds
volume
```

Session configuration is distinct from live runtime state.

---

## 18. Runtime State

Runtime state may include:

```text
current_set
current_phase
status
remaining_duration
phase_deadline
paused_phase
```

Do not mix persistent settings and runtime values into one unstructured object.

---

# Events

## 19. Semantic Timer Events

The timer engine should emit semantic events.

Examples:

```text
SessionStarted
PhaseStarted
CountdownThresholdReached
PhaseCompleted
SessionPaused
SessionResumed
SessionCompleted
SessionReset
```

External behavior should react to those events.

Example:

```text
Timer Engine
    ↓
CountdownThresholdReached(10)
    ↓
Announcement Service
    ↓
"还有 10 秒"
```

---

## 20. Timer Engine Must Not Speak Directly

Forbidden:

```text
TimerEngine:
    speech.speak("还有10秒")
```

Preferred:

```text
TimerEngine
    ↓
TimerEvent
    ↓
AnnouncementService
```

This allows speech to be:

- disabled
- replaced
- localized
- tested independently
- changed per platform

without changing timer logic.

---

# Audio and Speech

## 21. Speech Service

Speech is a desktop platform/application service.

Speech failure must not break the countdown.

Examples of valid degradation:

```text
TTS unavailable
→ continue timer
→ log warning
→ optionally play fallback sound
```

Timer state must remain valid even when audio output fails.

---

## 22. Speech Content

Speech strings should be generated from semantic events.

Examples:

```text
第 3 组开始
训练结束，开始休息
还有 10 秒
休息结束
全部训练完成
```

Do not embed literal announcement strings inside the timer state machine.

---

# Desktop UI Rules

## 23. Main Window

The main timer screen should prioritize:

```text
Current phase
Current set
Remaining time
Primary action
Secondary controls
```

The remaining time should be readable from several meters away.

Avoid filling the main screen with configuration controls while a session is running.

---

## 24. Natural Interaction

Prefer direct controls.

Examples:

```text
Start
Pause
Resume
Reset
Skip
```

Controls should change naturally with state.

Example:

```text
IDLE     → Start
WORK     → Pause
REST     → Pause
PAUSED   → Resume
COMPLETE → Done / Restart
```

Do not show actions that make no sense in the current state.

---

## 25. Keyboard Controls

Desktop usage should support useful keyboard shortcuts.

Suggested mappings:

```text
Space      Start / Pause / Resume
R          Reset
S          Skip phase
Esc        Close secondary panel/dialog
```

Shortcuts must not trigger unexpectedly while editing text fields.

---

## 26. Window Behavior

The application should behave as a desktop utility.

Potential features may include:

```text
always-on-top
compact mode
full-screen timer mode
system tray
remember window position
remember window size
```

These are optional features, not architectural requirements.

Do not implement them until needed.

---

## 27. Responsive Desktop Layout

The window should support reasonable resizing.

The UI should not assume a mobile portrait viewport.

Design primarily for desktop proportions.

Suggested minimum concept:

```text
compact window
normal desktop window
large/full-screen timer
```

Timer text should scale appropriately.

---

## 28. No Browser Layout Assumptions

Do not structure the application around:

```text
pages
URLs
routes
browser history
DOM layout
web breakpoints
HTTP navigation
```

Application navigation should use native desktop/QML state and components.

---

# QML Rules

## 29. QML Responsibilities

QML should primarily contain:

- components
- bindings
- animations
- visual states
- input handlers
- presentation logic

Complex business logic belongs outside QML.

Avoid large JavaScript blocks inside QML.

---

## 30. Reusable Components

Create reusable QML components only when reuse is real.

Examples may include:

```text
PrimaryButton.qml
DurationPicker.qml
TimerDisplay.qml
PhaseBadge.qml
SettingsRow.qml
```

Do not fragment every rectangle or label into a separate file.

---

## 31. Animations

Animations should be:

- short
- subtle
- interruptible
- non-blocking

Animation must never determine application state.

Do not wait for an animation callback before performing a timer phase transition.

Timer logic changes first; UI animates to reflect it.

---

## 32. Styling

Use centralized design tokens for visual consistency where practical.

Examples:

```text
spacing
corner_radius
font_sizes
animation_duration
opacity_levels
```

Avoid repeating arbitrary visual constants throughout QML.

Do not create a huge design-system framework for this small project.

---

# Platform Rules

## 33. Windows / Linux Isolation

Platform-specific behavior should be isolated.

Potential adapters:

```text
platform/
├── speech/
├── audio/
├── notifications/
├── filesystem/
└── desktop/
```

Core domain code must not contain platform-specific branching.

---

## 34. Filesystem

Never hard-code paths such as:

```text
C:\Users\...
/home/user/...
```

Use Qt/platform APIs to resolve application data and configuration locations.

---

## 35. Fonts

Do not assume one specific system font exists on both platforms.

Prefer an appropriate fallback stack or bundled application-safe strategy that respects licensing.

Do not distribute proprietary system fonts with the repository.

---

# Dependencies

## 36. Dependency Policy

Dependencies must be justified.

Before adding a production dependency:

1. Check whether Qt/current libraries already provide the functionality.
2. Confirm Windows support.
3. Confirm Linux support.
4. Check maintenance status.
5. Check licensing.
6. Assess package size and complexity.

Do not add a large dependency for a trivial function.

---

## 37. Avoid Web Dependencies

Do not add web UI dependencies such as:

```text
React
Vue
Angular
Next.js
Vite
Tailwind
Electron
Chromium wrappers
```

for the desktop UI.

The visual layer should remain Qt/QML-based unless the project's architecture is explicitly changed.

---

# Formatting and Linting

## 38. Formatter

Formatting must be automated.

Use the formatter configured for the chosen implementation language.

Typical examples:

```text
Python → Ruff format
C++    → clang-format
QML    → qmlformat
```

The repository configuration is authoritative.

Do not maintain competing formatters.

---

## 39. Linter

The target state is:

```text
0 lint errors
0 lint warnings
```

Possible tools depending on the stack:

```text
Python → Ruff
QML    → qmllint
C++    → clang-tidy / compiler warnings
```

Do not globally disable lint rules merely to obtain a passing build.

Suppressions must be narrow and justified.

---

## 40. Type Safety

If using Python:

```text
Pyright strict mode
```

or an equivalent strict configuration is preferred for core/application code.

Avoid uncontrolled `Any`.

If external Qt bindings require dynamic behavior, isolate the unsafe boundary and convert values into typed domain models.

---

# Testing

## 41. Testing Layers

Tests should be divided conceptually into:

```text
Unit
Integration
UI / E2E
```

Timer correctness belongs primarily in unit tests.

---

## 42. Required Timer Tests

At minimum test:

- session start
- preparation phase
- work phase
- work-to-rest transition
- rest-to-work transition
- set progression
- final completion
- pause
- resume
- repeated pause/resume
- reset
- skip if supported
- countdown thresholds
- zero/invalid configuration
- exact deadline boundary
- delayed update callback
- duplicate callback near deadline
- idempotent phase completion

---

## 43. Never Sleep in Timer Unit Tests

Forbidden:

```python
time.sleep(1)
```

or any equivalent real waiting.

Unit tests must use a fake clock.

Conceptually:

```text
clock.advance(10.0)
engine.update()
```

A test for a 30-minute session should complete almost instantly.

---

## 44. Fake Clock

Provide a deterministic fake monotonic clock.

Example interface:

```text
Clock
├── now()
└── FakeClock.advance(duration)
```

Production code uses the system monotonic clock.

Tests control time explicitly.

---

## 45. UI Tests

UI tests should focus on critical desktop flows.

Example:

```text
Launch application
→ configure work/rest/set values
→ start
→ pause
→ resume
→ complete
→ reset
```

Do not attempt to validate timer correctness using real-time UI waits.

Core behavior belongs in domain tests.

---

## 46. Animation Testing

Do not use pixel-perfect animation screenshots as the primary test mechanism.

Test:

- resulting state
- visible controls
- emitted actions
- final properties

Visual regression testing may be introduced later if it has real value.

---

## 47. Coverage

Recommended targets:

```text
Overall project           >= 80%
Timer/domain core         >= 95%
```

Coverage is not a substitute for meaningful behavioral assertions.

Do not write meaningless tests solely to increase the percentage.

---

# Error Handling

## 48. Never Swallow Errors

Forbidden:

```python
try:
    ...
except Exception:
    pass
```

Errors must be intentionally:

- handled
- logged
- transformed
- propagated

A failure in optional services should degrade gracefully.

---

## 49. Non-Critical Service Failures

These failures should normally not terminate the timer:

```text
speech unavailable
audio playback failure
notification failure
settings write failure during active session
```

The timer should continue when doing so remains correct and understandable.

---

# Logging

## 50. Meaningful Logging

Useful lifecycle events include:

```text
application_started
session_started
phase_started
session_paused
session_resumed
phase_completed
session_completed
speech_unavailable
settings_load_failed
```

Do not log every UI refresh or countdown decrement under normal operation.

---

# Code Structure

## 51. Example Repository Structure

The exact structure may evolve, but a desktop-focused layout could resemble:

```text
SetTimer/
├── AGENTS.md
├── README.md
├── pyproject.toml
├── src/
│   └── settimer/
│       ├── main.py
│       ├── application/
│       │   ├── controller.py
│       │   └── view_model.py
│       ├── domain/
│       │   ├── timer_engine.py
│       │   ├── state.py
│       │   ├── events.py
│       │   └── models.py
│       ├── services/
│       │   ├── clock.py
│       │   ├── speech.py
│       │   ├── audio.py
│       │   └── settings.py
│       └── ui/
│           ├── Main.qml
│           └── components/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── ui/
└── docs/
    ├── DESIGN.md
    └── ARCHITECTURE.md
```

This is a guideline, not a requirement to create empty directories in advance.

---

## 52. Avoid Premature Architecture

Do not create empty abstractions simply because they appear in the suggested directory layout.

Only add files and layers when they serve real code.

Prefer a smaller working structure over a large empty architecture.

---

# Git

## 53. Conventional Commits

Use Conventional Commits.

Preferred types:

```text
feat
fix
refactor
perf
test
docs
build
ci
chore
```

Format:

```text
<type>(optional-scope): <short description>
```

Examples:

```text
feat(timer): add configurable rest intervals
feat(ui): add animated timer phase transition
fix(timer): prevent drift after resume
fix(ui): preserve focus after duration edit
refactor(core): extract monotonic clock
test(timer): cover delayed update callbacks
docs: document desktop architecture
chore: update development tooling
```

Avoid:

```text
update
changes
fix stuff
misc
wip
优化
修改一下
```

---

## 54. Commit Scope

One commit should represent one coherent change.

Do not combine:

```text
new feature
+
unrelated refactor
+
dependency upgrade
+
format entire repository
```

unless they are inseparable.

Keep diffs easy to review.

---

# Quality Gate

## 55. Canonical Check Command

The project should expose one canonical local quality command.

Preferred example:

```text
make check
```

or an equivalent project script.

It should run applicable checks:

```text
formatter check
↓
QML lint
↓
language lint
↓
type check
↓
unit tests
↓
integration tests
↓
build
```

A task is not complete while required checks fail.

---

## 56. Build Validation

Changes affecting desktop UI or packaging must be validated by building or launching the application when practical.

The application should eventually be tested in CI on:

```text
Windows
Linux
```

Platform-specific problems should not be deferred until release.

---

# Agent Workflow

## 57. Before Editing

An agent must:

1. Read this file.
2. Inspect relevant existing files.
3. Understand current architecture.
4. Identify related tests.
5. Avoid unrelated modifications.
6. Preserve the desktop-only direction.

---

## 58. During Editing

An agent must:

1. Keep timer logic outside QML.
2. Use monotonic time for elapsed duration.
3. Preserve explicit state-machine semantics.
4. Add/update tests for behavior changes.
5. Avoid unnecessary dependencies.
6. Avoid unnecessary abstraction.
7. Keep platform-specific code isolated.
8. Keep the application as a desktop GUI.

---

## 59. After Editing

An agent must:

1. Run formatter.
2. Run QML lint where applicable.
3. Run language linter.
4. Run type checker.
5. Run relevant tests.
6. Run the full quality gate when practical.
7. Review the final diff.
8. Report:
   - changed behavior
   - changed files
   - tests added/updated
   - checks executed
   - known limitations

Never claim a check passed if it was not actually run.

---

# Forbidden Patterns

## 60. Explicitly Forbidden

Do not:

- convert the application into a website
- introduce browser-based routing
- introduce a web server for the GUI
- introduce Electron
- use React/Vue/HTML/CSS for the main UI
- use UI refresh ticks as elapsed time
- use wall-clock time as timer truth
- place timer business logic in QML
- use real `sleep()` in timer unit tests
- couple timer state directly to speech implementation
- scatter Windows/Linux branches through domain code
- add dependencies without a concrete reason
- silently swallow exceptions
- disable tests to obtain a green build
- weaken assertions just to make tests pass
- globally suppress lint/type errors
- rewrite unrelated code during a feature task
- introduce speculative architecture
- silently change timer semantics
- claim tests passed without running them

---

# Definition of Done

## 61. General Task Completion

A task is complete only when:

- requested behavior is implemented
- desktop architecture is preserved
- relevant tests exist
- formatter passes
- lint passes
- type checks pass where configured
- relevant tests pass
- build succeeds where applicable
- no unrelated files were changed
- documentation is updated when necessary

---

## 62. Timer-Specific Completion

For timer-related changes, also verify:

- monotonic time remains authoritative
- pause/resume semantics are correct
- delayed UI callbacks do not create drift
- phase transitions occur exactly once
- countdown threshold events do not duplicate
- tests do not depend on real waiting

---

## 63. UI-Specific Completion

For UI changes, also verify:

- timer logic was not moved into QML
- controls match current state
- layout works at expected desktop window sizes
- keyboard interactions remain usable
- animations do not block domain transitions
- Windows/Linux assumptions were not introduced accidentally

---

# Final Principle

SetTimer should be developed as:

> **a small, polished Windows/Linux desktop timer with iPhone-like interaction quality**

not as:

> a web application packaged as a desktop application.

Keep the system simple, deterministic, testable, and desktop-native in structure.
