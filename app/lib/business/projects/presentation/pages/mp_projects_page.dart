import 'package:flutter/cupertino.dart';
import 'package:omi/business/projects/presentation/pages/mp_create_project_page.dart';
import 'package:omi/business/projects/presentation/pages/mp_project_detail_page.dart';
import 'package:omi/business/shared/state/mp_business_controller.dart';

class MPProjectsPage extends StatelessWidget {
  const MPProjectsPage({
    super.key,
    required this.controller,
  });

  final MPBusinessController controller;

  @override
  Widget build(BuildContext context) {
    final projects = controller.projects;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Projects'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (_) => const MPCreateProjectPage(),
              ),
            );
          },
          child: const Text('New'),
        ),
      ),
      child: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return CupertinoListTile(
              title: Text(project.name),
              subtitle: Text(project.overview),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => MPProjectDetailPage(project: project),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
