import 'package:flutter/material.dart';

class ActivityPackProgressDialog extends StatelessWidget {
  final String title;
  final int currentActivity;
  final int totalActivities;
  final String currentActivityName;

  const ActivityPackProgressDialog({
    super.key,
    required this.title,
    required this.currentActivity,
    required this.totalActivities,
    required this.currentActivityName,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalActivities > 0 ? currentActivity / totalActivities : 0.0;
    final percentage = (progress * 100).toInt();

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.deepPurple[700]!,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$currentActivity de $totalActivities actividades',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.deepPurple[700]!,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Colors.deepPurple[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Generando: $currentActivityName',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void show({
    required BuildContext context,
    required String title,
    required int currentActivity,
    required int totalActivities,
    required String currentActivityName,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ActivityPackProgressDialog(
        title: title,
        currentActivity: currentActivity,
        totalActivities: totalActivities,
        currentActivityName: currentActivityName,
      ),
    );
  }

  static void update({
    required BuildContext context,
    required String title,
    required int currentActivity,
    required int totalActivities,
    required String currentActivityName,
  }) {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
      show(
        context: context,
        title: title,
        currentActivity: currentActivity,
        totalActivities: totalActivities,
        currentActivityName: currentActivityName,
      );
    }
  }

  static void dismiss(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }
}
