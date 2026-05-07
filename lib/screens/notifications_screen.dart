import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:incident_reporter/services/driver_app_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DriverAppController.instance;

    return Obx(() {
      final notifications = controller.notifications;
      return Scaffold(
        appBar: AppBar(title: const Text('Dispatch alerts')),
        body: notifications.isEmpty
            ? const Center(
                child: Text(
                    'No dispatch alerts yet. New websocket messages will appear here.'),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFE6EA),
                        child: Icon(Icons.notifications_active,
                            color: Color(0xFFDA3E52)),
                      ),
                      title: Text(item.title),
                      subtitle: Text(item.message),
                      trailing: Text(
                        '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  );
                },
              ),
      );
    });
  }
}
