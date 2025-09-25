import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountHeader extends StatelessWidget {
  const AccountHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Kullanıcı';
    final email = user?.email ?? '';
    final photo = user?.photoURL;

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: photo != null ? NetworkImage(photo) : null,
          child: photo == null
              ? Text(
                  name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              if (email.isNotEmpty)
                Text(email, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}