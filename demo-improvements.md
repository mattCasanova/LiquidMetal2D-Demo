# Demo Improvements Plan

## Context

The demo scenes work but have generic names, some code quality issues, and don't showcase newer library features (easing, bezier, Vec2 instance methods). The input demo in particular doesn't effectively demonstrate input handling.

## Checklist

- [ ] 1. Update scene titles to be descriptive
- [ ] 2. Overhaul Input Demo (camera zoom, corner ships, easing)
- [ ] 3. Add Bezier Curve demo scene
- [ ] 4. Code quality pass on all scenes

---

## 1. Scene Title Renames

| Scene | Old Title | New Title |
|-------|-----------|-----------|
| visualDemo | "Visual Demo" | "4,500 Ships - Batched Rendering" |
| inputDemo | "Input Demo" | "Touch Input & Camera Zoom" |
| explosionDemo | "Explosion Demo" | "4,500 Ships - Touch Rotation" |
| schedulerDemo | "Scheduler Demo" | "Timed Tasks & Callbacks" |
| stateDemo | "State Machine Demo" | "Behavior / State Pattern" |
| collisionDemo | "Collision Demo" | "Circle Collision & AI" |
| pauseDemo | "Paused" | "Paused" (unchanged) |

Files: `SceneTypes.swift` (title computed property)

---

## 2. Input Demo Overhaul

Replace the current "spawn ships at touch point" demo with one that shows off:
- **Center ship** that orients toward touch point (like current StateDemo but centered)
- **Four corner ships** pinned to world-space corners via `getWorldBoundsFromCamera`
- **Camera zoom** — touch toggles zoom in/out (Z distance change)
- **Easing** on the camera zoom (e.g., `Easing.easeInOutCubic`)
- Corner ships reposition each frame as bounds change during zoom

This demonstrates: touch input, screen-to-world conversion, world bounds, camera manipulation, easing functions.

Implementation:
- 5 objects total (1 center + 4 corners)
- Center ship: large (3x scale), rotates toward touch via `atan2`
- Corner ships: small (1.5x scale), reposition to `(bounds.maxX - offset, bounds.maxY - offset)` etc.
- Touch triggers zoom toggle: camera Z lerps between 30 and 70 over ~1 second using easing
- Use `GameMath.lerp` with `Easing.easeInOutCubic(t)` for smooth zoom

Files: `InputDemo.swift` (full rewrite), remove `RandomAngleBehavior`/`RandomAngleState` dependency

---

## 3. New Bezier Curve Demo

New scene showing a ship following a cubic bezier path.

- 4 control point markers (small ships or dots at p0, p1, p2, p3)
- 1 ship that moves along the curve using `GameMath.cubicBezier`
- t increments each frame, loops back to 0 when reaching 1
- Touch input moves one of the control points (e.g., p1 or p2)
- Shows off: `GameMath.cubicBezier`, touch input, `atan2` for orientation along curve

Add to SceneTypes:
- `.bezierDemo` case
- Title: "Cubic Bezier Curves"
- Register in ViewController with TSceneBuilder

Files: new `BezierDemo.swift`, update `SceneTypes.swift`, update `ViewController.swift`

---

## 4. Code Quality Pass

Across all scenes:
- [ ] ExplosionDemo: replace hardcoded 4500 with `GameConstants.MAX_OBJECTS`
- [ ] InputDemo: remove unsafe `as! BehaviorObj` cast (replaced by overhaul)
- [ ] StateDemo: don't recreate objects on resize, just reposition
- [ ] Use `Vec2` instance methods where applicable (`.distance(to:)`, `.dot()`, `.normalized`)
- [ ] Replace magic numbers with named constants where obvious
- [ ] Consistent use of `GameMath.degreeToRadian` vs raw math

---

## Verification

Build demo on iOS Simulator:
```bash
xcodebuild -project .../LiquidMetal2D-Demo.xcodeproj -scheme LiquidMetal2D-Demo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skipPackagePluginValidation build
```
