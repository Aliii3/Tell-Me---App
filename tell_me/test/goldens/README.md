# Golden tests — aurora design system

These render the shared design-system pieces (aurora background, frosted glass
card, holographic panel, lavender highlight, dark bento card) against committed
reference images, so palette or contrast changes can't land silently.

Full screens are intentionally not golden-tested: they pull in Firebase, Hive,
and platform channels (TTS/speech), which makes those tests flaky and slow.
The design system is where every screen's visual identity comes from, so a
regression here means a regression everywhere.

## Commands

```bash
# Run
flutter test test/goldens

# Re-approve after an intentional design change
flutter test test/goldens --update-goldens
```

Golden PNGs live in `test/goldens/goldens/` and should be committed with any
intentional design change.
