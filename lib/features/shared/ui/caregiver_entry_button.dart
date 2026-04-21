import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CaregiverEntryButton extends StatefulWidget {
  const CaregiverEntryButton({super.key});

  @override
  State<CaregiverEntryButton> createState() => _CaregiverEntryButtonState();
}

class _CaregiverEntryButtonState extends State<CaregiverEntryButton> {
  Timer? _timer;
  double _progress = 0.0;

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

  void _startPress(BuildContext context) {
    const duration = Duration(milliseconds: 2500);
    const tick = Duration(milliseconds: 50);

    int elapsed = 0;

    _timer = Timer.periodic(tick, (timer) {
      elapsed += tick.inMilliseconds;
      setState(() {
        _progress = elapsed / duration.inMilliseconds;
      });

      if (elapsed >= duration.inMilliseconds) {
        timer.cancel();
        _progress = 0;
        _enterCaregiverMode(context);
      }
    });
  }

  void _cancelPress() {
    _timer?.cancel();
    setState(() {
      _progress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: GestureDetector(
        onTapDown: (_) => _startPress(context),
        onTapUp: (_) => _cancelPress(),
        onTapCancel: _cancelPress,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.settings_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Caregiver Mode',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Hold to enter',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_progress > 0)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
