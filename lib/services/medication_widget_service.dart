import 'package:home_widget/home_widget.dart';

Future<void> updateMedicationWidget({
  required String nextDoseTime,
  required bool morningDone,
  required bool lunchDone,
  required bool dinnerDone,
}) async {
  await HomeWidget.saveWidgetData<String>(
    'next_dose',
    nextDoseTime,
  );

  await HomeWidget.saveWidgetData<bool>(
    'morning_done',
    morningDone,
  );

  await HomeWidget.saveWidgetData<bool>(
    'lunch_done',
    lunchDone,
  );

  await HomeWidget.saveWidgetData<bool>(
    'dinner_done',
    dinnerDone,
  );

  await HomeWidget.updateWidget(
    qualifiedAndroidName:
        'com.example.medicine_app.MedicationWidgetProvider',
  );
}
