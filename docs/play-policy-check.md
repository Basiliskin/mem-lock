# Google Play Location Policy Check

Checked 2026-10-31 from Google's help pages, as part of S0. This is a reading of the policy, not a review result. Only a real Play Console submission can confirm approval. Check the live pages again before submitting.

## What applies

- Always-on watching needs background location, whether through `ACCESS_BACKGROUND_LOCATION` or a foreground service used in an equivalent way.
- Background location must go through a Play Console declaration, including a video of the feature and an in-app disclosure that uses the word "location" and lists each feature using it.
- It is allowed only when it is central to the app and gives a significant user benefit. Google's examples are physical safety, perceived safety, and health and fitness. "Convenience" is listed as a minimal benefit.
- Updated rules become mandatory on January 27, 2027. Apps targeting Android 17 (API 37+) must use the Android location button for one-time or infrequent location requests. Background access still follows the review above.

## What this means for Geo Alert

1. **Main risk:** reminding someone about a bag could be judged as convenience, which is not listed as a significant benefit. Being central to the app helps, but approval is not assured. Rejection would remove always-on watching on Google Play, and with it the current product design.
2. **Test before S3:** submit a minimal build with the declaration to Play's internal testing track once a developer account exists. Describe the honest benefit: helping elderly people, including those with memory difficulties, avoid losing belongings. Do not present it as a safety app unless that is true.
3. **Setup needs a location disclosure** (input for S10), shown before the permission request.
4. **Marking a Quiet Place** is a one-time request, so check whether it needs the location button when the target reaches API 37.
5. **Fallback if rejected:** distribute outside Google Play (a direct download or another store), or redesign around a start action by the Wearer, which conflicts with the no-buttons decision. This decision is the user's to make.

## Sources

- [Understanding location in the background permissions](https://support.google.com/googleplay/android-developer/answer/9799150?hl=en)
- [Permissions and APIs that Access Sensitive Information](https://support.google.com/googleplay/android-developer/answer/16558241?hl=en)
- [Understanding foreground service and full-screen intent requirements](https://support.google.com/googleplay/android-developer/answer/13392821?hl=en)
- [Policy announcement: October 29, 2026](https://support.google.com/googleplay/android-developer/answer/18100766)
- [Minimum Scope: Foreground Location Access and the Location Button](https://support.google.com/googleplay/android-developer/answer/17033915)
