package com.receipt.fold.receipt_fold
import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import HomeWidgetGlanceWidgetReceiver
import android.content.Context
import android.graphics.BitmapFactory
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.currentState
import androidx.glance.layout.ContentScale
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.fillMaxSize
import androidx.glance.text.Text

class HomeWidgetMobile : HomeWidgetGlanceWidgetReceiver<HomeWidgetMobileWidget>() {
    override val glanceAppWidget = HomeWidgetMobileWidget()
}

class HomeWidgetMobileWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*>
        get() = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            GlanceContent(context, currentState())
        }
    }

    @Composable
    private fun GlanceContent(context: Context, currentState: HomeWidgetGlanceState) {
        val prefs = currentState.preferences
        val imagePath = prefs.getString("HomeWidgetMobilePath", null)

        Box (
            modifier = GlanceModifier
                .fillMaxSize()
                .background(Color.White)
                .clickable(actionStartActivity<MainActivity>()),
            contentAlignment = Alignment.Center
        ) {
            imagePath?.let {
                val bitmap = BitmapFactory.decodeFile(it)
                Image(
                    androidx.glance.ImageProvider(bitmap),
                    null,
                    GlanceModifier,
                    ContentScale.Crop
                )
            } ?: Text("尚未設定載具")
        }
    }
}
