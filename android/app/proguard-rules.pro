# google_mlkit_text_recognition's plugin code references recognizer
# classes for every script it supports (chinese/devanagari/japanese/
# korean), but this app only depends on the latin text-recognition
# module (see OcrService — TextRecognitionScript.latin) and never adds
# the other per-script ML Kit dependencies. R8 can't resolve those
# classes at release/minify time and fails the build over it by default;
# these are genuinely absent (not a bug) and never reached at runtime,
# so it's safe to tell R8 not to warn/fail on them. Exact rules R8 itself
# suggested via build/app/outputs/mapping/release/missing_rules.txt.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
