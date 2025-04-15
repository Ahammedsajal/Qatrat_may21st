# Stripe SDK Rules
-keep class com.stripe.** { *; }
-keepclassmembers class com.stripe.** { *; }
-dontwarn com.stripe.**

# Push Provisioning Rules
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider

# React Native Stripe SDK Rules (if used)
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.reactnativestripesdk.**

# General ProGuard optimizations
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn javax.annotation.**
