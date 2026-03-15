# Merge Demo Projects into One

## Context

Two demo projects exist: LiquidMetal2D-Demo (2 scenes, cleaner structure, has push/pop) and LiquidMetal2D-test (5 scenes, more features). Goal is to merge into one comprehensive demo with all unique scenes, eliminate redundancy, and archive the test project.

## Recommendation: Migrate Test scenes INTO Demo

The Demo project is the better base:
- Cleaner directory structure (flat source folder vs deeply nested)
- Already has push/pop scene stacking wired up
- Better project name ("LiquidMetal2D-Demo")
- Fewer structural changes needed — just add files

## Scene Roster (7 scenes)

| # | Name | Source | Demonstrates |
|---|------|--------|-------------|
| 0 | VisualDemo | Demo (keep) | Mass rendering, z-depth 0-60, camera oscillation, Scheduler, color cycling |
| 1 | InputDemo | Demo (keep) | Touch-spawn at location, scale-based depth sorting |
| 2 | ExplosionDemo | Test's SecondScene (rename) | Ships from center, touch rotates ALL ships, DefaultScene delegation |
| 3 | SchedulerDemo | Test's ThirdScene (rename) | ScheduledTask with count=4, onComplete callback, finite task lifecycle |
| 4 | StateDemo | Test's StateTestScene (rename) | PlayerStateMachine, single-object Behavoir pattern, touch-to-rotate |
| 5 | CollisionDemo | Test's CollisionScene (rename) | FindAndGo AI, CircleCollider, infection mechanic, object pooling |
| 6 | PauseDemo | New | Push/pop as pause overlay — demonstrates scene stacking use case |

**Dropped:** Test's InitialScene — redundant with Demo's VisualDemo (which is better: has z-depth variation, camera oscillation, Scheduler).

## Checklist

### Phase 1: Copy helper classes from Test into Demo
- [ ] `CollisionObj.swift` — as-is
- [ ] `PlayerStateMachine.swift` — rename `BehavoirGameObj` → `BehavoirObj`
- [ ] `PlayerState.swift` — rename `BehavoirGameObj` → `BehavoirObj`
- [ ] `FindAndGoBehavoir.swift` — as-is
- [ ] `FindAndGoStates.swift` — as-is

### Phase 2: Copy and adapt scenes from Test
- [ ] `ExplosionDemo.swift` — from SecondScene, rename class, update nav
- [ ] `SchedulerDemo.swift` — from ThirdScene, rename class, update nav
- [ ] `StateDemo.swift` — from StateTestScene, rename class + BehavoirGameObj→BehavoirObj
- [ ] `CollisionDemo.swift` — from CollisionScene, rename class, update nav

### Phase 3: Create PauseDemo (freeze-frame style)
- [ ] New scene — the pushed scene stays visible underneath (Metal doesn't clear)
- [ ] Overlay a tinted UIView on top to give a "frozen" look
- [ ] Add "Paused" label and centered "Resume" button
- [ ] Resume button calls `sceneMgr.popScene()`
- [ ] Excluded from Prev/Next cycle — only reachable via Push
- [ ] No game objects, no rendering — just UI overlay on top of the frozen frame

### Phase 4: Update SceneTypes
- [ ] 7 cases: visualDemo, inputDemo, explosionDemo, schedulerDemo, stateDemo, collisionDemo, pauseDemo
- [ ] `next()`/`prev()` return `SceneTypes?` — nil at the ends (non-cyclic)
- [ ] `prev()` returns nil for visualDemo (first), `next()` returns nil for collisionDemo (last)
- [ ] pauseDemo excluded from navigation — only reachable via Pause button
- [ ] Add `title` computed property: "Visual Demo", "Input Demo", etc.

### Phase 5: Update all navigable scenes with consistent UI
- [ ] All scenes get: title label (top center) + Prev (bottom-left) / Pause (bottom-center, red) / Next (bottom-right)
- [ ] Prev button hidden on first scene (visualDemo), Next button hidden on last scene (collisionDemo)
- [ ] Pause button calls `sceneMgr.pushScene(type: .pauseDemo)` and hides uiView
- [ ] `resume()` shows uiView again after pop
- [ ] VisualDemo — update from Push to Pause, add title
- [ ] InputDemo — replace Pop with Pause, add title

### Phase 6: Update ViewController
- [ ] Register all 7 scenes in scene factory
- [ ] Start on visualDemo

### Phase 7: Add files to Xcode project (pbxproj)
- [ ] Add all 10 new .swift files to build sources

### Phase 8: Build, test, commit
- [ ] Verify all 7 scenes render and navigate correctly
- [ ] Verify Push → PauseDemo → Pop returns to previous scene
- [ ] Commit and push

### Phase 9: Archive Test project
- [ ] Update LiquidMetal2D-test README to say merged into Demo
- [ ] Delete locally

## Key decisions
- **BehavoirObj** is the canonical name (Demo's existing class). Test's `BehavoirGameObj` references get renamed.
- **PauseDemo** is push-only, not in the Prev/Next cycle. Every navigable scene gets a "Pause" button (red, center) that pushes PauseDemo. Behind the scenes it's `pushScene`/`popScene`.
- **InputDemo** loses its Pop button (no longer the push target). Gets Pause button like all other scenes.

## Verification
1. Build succeeds with 0 errors
2. Navigation: Prev/Next goes visualDemo → inputDemo → explosionDemo → schedulerDemo → stateDemo → collisionDemo
3. Prev hidden on first scene (visualDemo), Next hidden on last scene (collisionDemo)
4. Title label visible at top of each scene
5. Pause on any scene opens PauseDemo freeze-frame overlay
6. Resume from PauseDemo returns to the scene that paused, with UI restored
7. Touch input works in scenes that use it (InputDemo, ExplosionDemo, StateDemo)
8. Collision detection works in CollisionDemo
