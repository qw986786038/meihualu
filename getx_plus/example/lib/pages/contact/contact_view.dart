import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'contact_logic.dart';

class ContactView extends StatelessWidget {
  const ContactView({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ContactLogic>();
    return Scaffold(
      appBar: AppBar(title: const Text('联系人')),
      body: Obx(
        () => ListView.builder(
          itemCount: logic.contacts.length,
          itemBuilder: (_, index) {
            final contact = logic.contacts[index];
            return ListTile(
              leading: CircleAvatar(child: Text(contact['name']![0])),
              title: Text(contact['name']!),
              subtitle: Text(contact['phone']!),
              trailing: IconButton(
                icon: const Icon(Icons.phone),
                onPressed: () {},
              ),
            );
          },
        ),
      ),
    );
  }
}
