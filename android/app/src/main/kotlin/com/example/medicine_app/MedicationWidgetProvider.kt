package com.example.medicine_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class MedicationWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        // 이 값에는 "오후 1:00"처럼 시각만 저장해요.
        val nextDose = widgetData.getString(
            "next_dose",
            "미설정"
        ) ?: "미설정"

        val morningDone = widgetData.getBoolean(
            "morning_done", false
        )

        val lunchDone = widgetData.getBoolean(
            "lunch_done", false
        )

        val dinnerDone = widgetData.getBoolean(
            "dinner_done", false
        )

        val completed = listOf(
            morningDone,
            lunchDone,
            dinnerDone
        ).count { it }

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(
                context.packageName,
                R.layout.medication_widget
            )

            views.setTextViewText(
                R.id.text_next_dose,
                nextDose
            )

            fun showCheck(
                checkId: Int,
                rowId: Int,
                name: String,
                done: Boolean
            ) {
                views.setTextViewText(
                    checkId,
                    if (done) "☑" else "☐"
                )

                views.setContentDescription(
                    rowId,
                    "$name, ${if (done) "복용 완료" else "복용 전"}"
                )
            }

            showCheck(
                R.id.check_morning,
                R.id.row_morning,
                "아침",
                morningDone
            )

            showCheck(
                R.id.check_lunch,
                R.id.row_lunch,
                "점심",
                lunchDone
            )

            showCheck(
                R.id.check_dinner,
                R.id.row_dinner,
                "저녁",
                dinnerDone
            )

            views.setTextViewText(
                R.id.text_progress,
                "$completed/3 복용 완료"
            )

            // 완료 횟수만큼 아래에서 위로 채워요.
            fun fillSlot(viewId: Int, filled: Boolean) {
                views.setInt(
                    viewId,
                    "setBackgroundResource",
                    if (filled) {
                        R.drawable.med_slot_filled
                    } else {
                        R.drawable.med_slot_empty
                    }
                )
            }

            fillSlot(R.id.bottle_bottom, completed >= 1)
            fillSlot(R.id.bottle_middle, completed >= 2)
            fillSlot(R.id.bottle_top, completed >= 3)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
