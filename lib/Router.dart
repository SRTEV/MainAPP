import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Controllers/AuthController.dart';
import 'RepairmanViewModels/RepairmanMap.dart';
import 'ViewModels/Login.dart';
import 'ViewModels/map.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, child) {
        if (auth.token == null) {
          return const Login();
        }

        if (auth.RMode) {
          return const Repairmanmap();
        }

        return const MapPage();
      },
    );
  }
}
