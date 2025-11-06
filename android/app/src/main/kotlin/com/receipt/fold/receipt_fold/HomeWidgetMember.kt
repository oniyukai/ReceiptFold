package com.receipt.fold.receipt_fold
import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import HomeWidgetGlanceWidgetReceiver
import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.currentState
import androidx.glance.action.clickable
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.action.actionStartActivity
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.fillMaxSize
import androidx.glance.text.Text
import androidx.glance.layout.ContentScale
import android.graphics.BitmapFactory
import androidx.glance.Image
import androidx.glance.action.actionParametersOf

class HomeWidgetMember : HomeWidgetGlanceWidgetReceiver<HomeWidgetMemberWidget>() {
    override val glanceAppWidget = HomeWidgetMemberWidget()
}

class HomeWidgetMemberWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            GlanceContent(context, currentState())
        }
    }

    @Composable
    private fun GlanceContent(context: Context, currentState: HomeWidgetGlanceState) {
        val prefs = currentState.preferences
        val itemLength = prefs.getInt("HomeWidgetMemberItemLength", 0)
        val currentIndex = prefs.getInt(CURRENT_INDEX_KEY, -1)

        if (itemLength == 0) {

            Box (
                modifier = GlanceModifier
                    .fillMaxSize()
                    .background(Color.White)
                    .clickable(actionStartActivity<MainActivity>()),
                contentAlignment = Alignment.Center
            ) {
                Text("尚未設定會員")
            }

        } else {
            if (currentIndex != -1) {
                val barcodeKey = "HomeWidgetMemberItemBarcodes[$currentIndex]"
                val barcodePath = prefs.getString(barcodeKey, null)

                Box (
                    modifier = GlanceModifier
                        .fillMaxSize()
                        .background(Color.White)
                        .clickable(onClick = actionRunCallback<SelectCardAction>()),
                    contentAlignment = Alignment.Center
                ) {
                    barcodePath?.let {
                        val bitmap = BitmapFactory.decodeFile(it)
                        Image(
                            androidx.glance.ImageProvider(bitmap),
                            null,
                            GlanceModifier,
                            ContentScale.Crop
                        )
                    } ?: Text("未找到$barcodeKey")
                }

            } else {

                androidx.glance.layout.Row(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    for (index in 0 until itemLength) {
                        val imageKey = "HomeWidgetMemberItemImages[$index]"
                        val imagePath = prefs.getString(imageKey, null)
                        imagePath?.let {
                            val bitmap = BitmapFactory.decodeFile(it)
                            Image(
                                provider = androidx.glance.ImageProvider(bitmap),
                                contentDescription = null,
                                modifier = GlanceModifier
                                    .defaultWeight()
                                    .clickable(onClick = actionRunCallback<ShowBarcodeAction>(
                                        parameters = actionParametersOf(ActionParamKeys.Index to index)
                                    )),
                                contentScale = ContentScale.Crop
                            )
                        }
                    }
                }

            }
        }
    }
}

const val CURRENT_INDEX_KEY = "HomeWidgetMemberItemIndex"

object ActionParamKeys {
    val Index = ActionParameters.Key<Int>("index")
}

class SelectCardAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        val dataStore = HomeWidgetGlanceStateDefinition().getDataStore(context, glanceId.toString())
        dataStore.updateData { currentState: HomeWidgetGlanceState ->
            val newPreferences: SharedPreferences = currentState.preferences
            newPreferences.edit().putInt(CURRENT_INDEX_KEY, -1).apply()
            HomeWidgetGlanceState(newPreferences)
        }
        HomeWidgetMemberWidget().update(context, glanceId)
    }
}

class ShowBarcodeAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        val index = parameters[ActionParamKeys.Index] ?: 0
        val dataStore = HomeWidgetGlanceStateDefinition().getDataStore(context, glanceId.toString())
        dataStore.updateData { currentState: HomeWidgetGlanceState ->
            val newPreferences: SharedPreferences = currentState.preferences
            newPreferences.edit().putInt(CURRENT_INDEX_KEY, index).apply()
            HomeWidgetGlanceState(newPreferences)
        }
        HomeWidgetMemberWidget().update(context, glanceId)
    }
}