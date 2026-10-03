import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Controllers/AuthController.dart';
import 'Modules/BlockChecker.dart';
import 'RepairmanViewModels/RepairmanMap.dart';
import 'ViewModels/Blocked.dart';
import 'ViewModels/Login.dart';
import 'ViewModels/map.dart';

class RoleRouter extends StatefulWidget {
  const RoleRouter({Key? key}) : super(key: key);

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  bool _checkingBan = true;
  bool _isBlocked = false;

  String? _lastToken;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUser();
    });
  }

  Future<void> _checkUser() async {
    if (!mounted) return;

    final auth = context.read<AuthController>();

    // Nie ma zalogowanego użytkownika.
    if (auth.token == null) {
      if (!mounted) return;

      setState(() {
        _checkingBan = false;
        _isBlocked = false;
      });

      return;
    }

    // Nie sprawdzamy tego samego tokenu ponownie.
    if (_lastToken == auth.token && !_checkingBan) {
      return;
    }

    _lastToken = auth.token;

    setState(() {
      _checkingBan = true;
    });

    final blocked = await BlockChecker.check(context);

    if (!mounted) return;

    setState(() {
      _isBlocked = blocked;
      _checkingBan = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, child) {

        if (auth.token == null) {
          return const Login();
        }

        if (_checkingBan) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            ),
          );
        }

        if (_isBlocked) {
          return const Blocked();
        }

        if (auth.RMode) {
          return const Repairmanmap();
        }

        return const MapPage();
      },
    );
  }
}