# Geo Alert patch

A copy of activity_recognition_flutter 6.1.0, without its `example/` and `test/` folders.

**The change:** `onDetachedFromEngine` in `ActivityRecognitionFlutterPlugin.kt` calls `stopTracking()` only if this engine is listening. Upstream always calls it, and every engine shares one PendingIntent, so closing the screens would stop updates for the running service.

When updating the plugin, reapply this change or confirm that upstream has fixed it.
