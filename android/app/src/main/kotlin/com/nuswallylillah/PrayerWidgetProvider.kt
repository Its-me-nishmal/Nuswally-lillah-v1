package com.nuswallylillah

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class PrayerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_UPDATE_PRAYER_WIDGET || intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, PrayerWidgetProvider::class.java)
            val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (widgetId in allWidgetIds) {
                updateAppWidget(context, appWidgetManager, widgetId)
            }
        }
    }

    companion object {
        const val ACTION_UPDATE_PRAYER_WIDGET = "com.nuswallylillah.ACTION_UPDATE_PRAYER_WIDGET"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_prayer_times)

            // Read live values stored by Flutter in FlutterSharedPreferences
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val nextPrayer = prefs.getString("flutter.widget_next_prayer", null) ?: "Prayer"
            val countdown = prefs.getString("flutter.widget_countdown", null) ?: "--"
            val hijriDate = prefs.getString("flutter.widget_hijri_date", null) ?: "Nuswally Lillah"
            val location = prefs.getString("flutter.widget_location", null) ?: "Kerala"
            val fajr = prefs.getString("flutter.widget_fajr", null) ?: "--:--"
            val dhuhr = prefs.getString("flutter.widget_dhuhr", null) ?: "--:--"
            val asr = prefs.getString("flutter.widget_asr", null) ?: "--:--"
            val maghrib = prefs.getString("flutter.widget_maghrib", null) ?: "--:--"
            val isha = prefs.getString("flutter.widget_isha", null) ?: "--:--"

            views.setTextViewText(R.id.widget_next_prayer, "Next: $nextPrayer")
            views.setTextViewText(R.id.widget_countdown, countdown)
            views.setTextViewText(R.id.widget_hijri_date, hijriDate)
            views.setTextViewText(R.id.widget_location, "$location • Accurate Timings")
            views.setTextViewText(R.id.widget_fajr_time, fajr)
            views.setTextViewText(R.id.widget_dhuhr_time, dhuhr)
            views.setTextViewText(R.id.widget_asr_time, asr)
            views.setTextViewText(R.id.widget_maghrib_time, maghrib)
            views.setTextViewText(R.id.widget_isha_time, isha)

            // Open App on widget click
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
