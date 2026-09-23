package com.mantic.document.organizer

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity, not FlutterActivity — local_auth's biometric
// prompt requires a FragmentActivity on Android.
class MainActivity : FlutterFragmentActivity()
