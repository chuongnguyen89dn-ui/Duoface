# Speedbubble candidate build checklist

- Baseline: exact native12 SHA256 `85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7`.
- Add only DuoFaceSpeedHUD, DuoFaceSpeedSources and GMapHUD 0.2.3 publishers for VietMap, Waze, GOFA; keep Native12 original payload files unchanged.
- Exclude GoogleMapsVietMap, GMapHUDPlacementRelay and GMapHUDOverspeedScreen because they introduce additional UI.
- Validate rootless arm64, filters, signing, copyright notices, package version, SHA256 and test artifact.
- CarPlay device functionality untested until installed on a jailbroken iPhone.
