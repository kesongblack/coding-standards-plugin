/// GOOD: snake_case file name, PascalCase class name
/// GOOD: Feature-based directory structure

import 'package:flutter/material.dart';

class UserCard extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;

  const UserCard({
    super.key,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (avatarUrl != null)
              CircleAvatar(backgroundImage: NetworkImage(avatarUrl!)),
            Text(name, style: Theme.of(context).textTheme.titleMedium),
            Text(email, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
