import 'package:flutter/cupertino.dart';
import 'package:omi/business/app_shell/presentation/mp_business_shell_page.dart';
import 'package:omi/business/shared/data/mp_business_repository.dart';

class MPBusinessApp extends StatelessWidget {
  const MPBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    const repository = MPBusinessRepository();
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: MPBusinessShellPage(repository: repository),
    );
  }
}
