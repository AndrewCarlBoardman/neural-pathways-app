
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/ui/caregiver_entry_button.dart';

class ReceiverHomeScreen extends StatelessWidget {
  const ReceiverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver Guides'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Spacer(),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Tap here to see your step-by-step guides',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SizedBox(
              width: double.infinity,
              height: 120,
              child: ElevatedButton(
                onPressed: () {
                  context.go('/receiver/guides');
                },
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('View Guides'),
              ),
            ),
          ),

          const Spacer(),

          const CaregiverEntryButton(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
