package com.alexisgk.mynotes

import io.flutter.embedding.android.FlutterFragmentActivity

// FragmentActivity (not FlutterActivity) is required by local_auth so the
// biometric prompt can be hosted in a fragment.
class MainActivity : FlutterFragmentActivity()
