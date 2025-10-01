// lib/screens/admin/set_menu_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // FIX: Corrected the import path
import 'package:provider/provider.dart';
import '../../provider/admin_provider.dart';

class SetMenuScreen extends StatefulWidget {
  SetMenuScreen({Key? key}) : super(key: key);

  @override
  _SetMenuScreenState createState() => _SetMenuScreenState();
}

class _SetMenuScreenState extends State<SetMenuScreen> {
  DateTime _selectedDate = DateTime.now();
  final _lunchController = TextEditingController();
  final _dinnerController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitMenu() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final success = await adminProvider.setDailyMenu(
      date: _selectedDate,
      lunchOptions: _lunchController.text,
      dinnerOptions: _dinnerController.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Menu updated successfully!' : adminProvider.error ?? 'Failed to update menu.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Daily Menu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM').format(_selectedDate),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    child: const Text('Change Date'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _lunchController,
              decoration: const InputDecoration(
                labelText: 'Lunch Options',
                hintText: 'Enter each lunch item on a new line...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _dinnerController,
              decoration: const InputDecoration(
                labelText: 'Dinner Options',
                hintText: 'Enter each dinner item on a new line...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 32),
            Consumer<AdminProvider>(
              builder: (context, provider, child) => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: provider.isSubmitting ? null : _submitMenu,
                  icon: const Icon(Icons.save),
                  label: provider.isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Menu'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}