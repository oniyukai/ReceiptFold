#-keep class com.receipt.fold.receipt_fold.** extends androidx.glance.appwidget.action.ActionCallback { <init>(); }

-keep class com.google.mlkit.** { *; }

-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
