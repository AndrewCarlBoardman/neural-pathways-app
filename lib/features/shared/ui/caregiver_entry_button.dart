
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CaregiverEntryButton extends StatelessWidget {
  const CaregiverEntryButton({super.key});

  Future<void> _enterCaregiverMode(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Enter Caregiver Mode?'),
          content: const Text(
            'This area allows editing and managing guides.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (result == true && context.mounted) {
      context.go('/guides');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _enterCaregiverMode(context),
      child: Column(
        children: const [
          Icon(
            Icons.settings,
            size: 28,
            color: Colors.grey,
          ),
          SizedBox(height: 4),
          Text(
            'Caregiver',
            style: TextStyle(color: Colors.grey),
          ),
          Text(
            'Hold',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
