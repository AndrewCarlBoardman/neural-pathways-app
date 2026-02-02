import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:caregiver_guides/shared/files/image_store.dart';
import 'package:caregiver_guides/shared/db/db_provider.dart';



class DeviceCreateScreen extends ConsumerStatefulWidget {
  const DeviceCreateScreen({super.key});

  @override
  ConsumerState<DeviceCreateScreen> createState() => _DeviceCreateScreenState();
}

class _DeviceCreateScreenState extends ConsumerState<DeviceCreateScreen> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  final _imageStore = const ImageStore();

  String? _savedPhotoPath;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null) return;

    final savedPath = await _imageStore.savePickedImageToAppDir(picked);
    setState(() => _savedPhotoPath = savedPath);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a device name')));
      return;
    }

    setState(() => _saving = true);
    try {
      final db = ref.read(dbProvider);
      await db.createDevice(name: name, coverPhotoPath: _savedPhotoPath);

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _savedPhotoPath == null ? null : File(_savedPhotoPath!);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Device')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Device photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(),
              ),
              child: preview == null
                  ? const Center(child: Text('No photo yet'))
                  : ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(preview, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take photo'),
          ),
          const SizedBox(height: 18),
          const Text('Device name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'e.g. TV Remote, Microwave, Tablet'),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
