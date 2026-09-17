import 'package:flutter/material.dart';
import 'package:mainapp/Controllers/AuthController.dart';
import 'package:provider/provider.dart';

class Repairmanmap extends StatelessWidget {
  const Repairmanmap({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Repairman Panel'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  auth.clearSomeData();
                },
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Hi, Repairman',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    auth.toggleRepairmanMode();
                  },
                  child: const Text('Change mode (User mode)'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
