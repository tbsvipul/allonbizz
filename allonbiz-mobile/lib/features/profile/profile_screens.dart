import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/models/app_models.dart';

final notificationsProvider = FutureProvider<List<UserNotificationItem>>((
  ref,
) async {
  final repo = ref.read(appRepositoryProvider);
  final items = await repo.getNotifications();
  await ref.read(appStorageProvider).writeCachedNotifications(items);
  return items;
});

final journeysProvider = FutureProvider<List<JourneySession>>((ref) async {
  return ref.read(appRepositoryProvider).getJourneys();
});

final savedItemsProvider = FutureProvider<List<SavedItem>>((ref) async {
  final repo = ref.read(appRepositoryProvider);
  final items = await repo.getSavedItems();
  await ref.read(appStorageProvider).writeCachedSavedItems(items);
  return items;
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final prefs = ref.watch(preferencesControllerProvider).preferences;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  foregroundColor: theme.colorScheme.primary,
                  child: Text(
                    auth.user != null && auth.user!.firstName.isNotEmpty
                        ? auth.user!.firstName[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.user?.displayName ?? 'User',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auth.user?.email ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.push('/profile/edit'),
                  icon: const Icon(Icons.edit_outlined),
                  color: theme.colorScheme.onPrimary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: prefs.darkMode,
                  title: const Text('Dark mode'),
                  subtitle: const Text(
                    'Switch between day and night map palettes.',
                  ),
                  onChanged: (value) => ref
                      .read(preferencesControllerProvider)
                      .setDarkMode(value),
                ),
                SwitchListTile(
                  value: prefs.notificationsEnabled,
                  title: const Text('Notifications'),
                  subtitle: const Text('Receive proximity deal alerts.'),
                  onChanged: (value) => ref
                      .read(preferencesControllerProvider)
                      .setNotificationsEnabled(value),
                ),
                SwitchListTile(
                  value: prefs.backgroundTrackingEnabled,
                  title: const Text('Background tracking'),
                  subtitle: const Text(
                    'Keep discovery alive while the app is minimized.',
                  ),
                  onChanged: (value) => ref
                      .read(preferencesControllerProvider)
                      .setBackgroundTrackingEnabled(value),
                ),
                ListTile(
                  title: const Text('Discovery radius'),
                  subtitle: Text(
                    '${prefs.discoveryRadiusKm.toStringAsFixed(1)} km',
                  ),
                  trailing: DropdownButton<double>(
                    value: prefs.discoveryRadiusKm,
                    items: const <double>[0.5, 1, 2, 5]
                        .map(
                          (value) => DropdownMenuItem<double>(
                            value: value,
                            child: Text(
                              '${value.toStringAsFixed(value == 0.5 ? 1 : 0)} km',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(preferencesControllerProvider)
                            .setDiscoveryRadius(value);
                      }
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Language'),
                  trailing: DropdownButton<String>(
                    value: prefs.language,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(preferencesControllerProvider)
                            .setLanguage(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_none_rounded),
                  title: const Text('Notifications inbox'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/profile/notifications'),
                ),
                ListTile(
                  leading: const Icon(Icons.route_rounded),
                  title: const Text('Past journeys'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/profile/journeys'),
                ),
                ListTile(
                  leading: const Icon(Icons.bookmark_border_rounded),
                  title: const Text('Saved offers'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/profile/saved'),
                ),
                ListTile(
                  leading: const Icon(Icons.analytics_outlined),
                  title: const Text('Trips analytics'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/trips'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.tonal(
            onPressed: () async {
              await ref.read(authControllerProvider).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _firstController = TextEditingController();
  final _lastController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _didSeedInitialValues = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSeedInitialValues) {
      return;
    }

    final user = ref.read(authControllerProvider).user;
    _firstController.text = user?.firstName ?? '';
    _lastController.text = user?.lastName ?? '';
    _phoneController.text = user?.phoneNumber ?? '';
    _didSeedInitialValues = true;
  }

  @override
  void dispose() {
    _firstController.dispose();
    _lastController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstController,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'First name is required.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastController,
                decoration: const InputDecoration(labelText: 'Last name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Last name is required.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone number'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }

                    try {
                      await ref
                          .read(appRepositoryProvider)
                          .updateProfile(
                            firstName: _firstController.text,
                            lastName: _lastController.text,
                            phoneNumber: _phoneController.text,
                          );
                      ref
                          .read(authControllerProvider)
                          .updateLocalProfile(
                            firstName: _firstController.text,
                            lastName: _lastController.text,
                            phoneNumber: _phoneController.text,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile updated.')),
                        );
                        context.pop();
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              error.toString().replaceFirst('Exception: ', ''),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final cached = ref.read(appStorageProvider).readCachedNotifications();
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notifications.when(
        loading: () => _NotificationList(items: cached),
        error: (error, _) =>
            Center(child: Text('Failed to load notifications: $error')),
        data: (items) => _NotificationList(items: items),
      ),
    );
  }
}

class _NotificationList extends ConsumerWidget {
  const _NotificationList({required this.items});

  final List<UserNotificationItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const Center(child: Text('No alerts yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(
                item.isRead
                    ? Icons.notifications_none
                    : Icons.notifications_active,
              ),
            ),
            title: Text(item.title),
            subtitle: Text(item.message),
            onTap: () async {
              await ref
                  .read(appRepositoryProvider)
                  .markNotificationRead(item.notificationId);
              ref.invalidate(notificationsProvider);
              if (context.mounted) {
                if (item.actionOfferId != null) {
                  context.push('/offer/${item.actionOfferId}');
                } else if (item.actionShopId != null) {
                  context.push('/shop/${item.actionShopId}');
                } else if (item.actionJourneyId != null) {
                  context.push('/trips?journeyId=${item.actionJourneyId}');
                }
              }
            },
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemCount: items.length,
    );
  }
}

class PastJourneysScreen extends ConsumerWidget {
  const PastJourneysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeys = ref.watch(journeysProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Past journeys')),
      body: journeys.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed to load journeys: $error')),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemBuilder: (context, index) {
            final journey = items[index];
            return Card(
              child: ListTile(
                title: Text(journey.destinationName ?? journey.startName),
                subtitle: Text(
                  '${journey.type} • ${NumberFormat.compact().format(journey.distanceMeters)} m • ${journey.durationSeconds ~/ 60} min',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () =>
                    context.push('/trips?journeyId=${journey.journeyId}'),
              ),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemCount: items.length,
        ),
      ),
    );
  }
}

class SavedOffersScreen extends ConsumerWidget {
  const SavedOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedItemsProvider);
    final cached = ref.read(appStorageProvider).readCachedSavedItems();
    return Scaffold(
      appBar: AppBar(title: const Text('Saved offers')),
      body: saved.when(
        loading: () => _SavedItemsList(items: cached),
        error: (error, _) =>
            Center(child: Text('Failed to load saved items: $error')),
        data: (items) => _SavedItemsList(items: items),
      ),
    );
  }
}

class _SavedItemsList extends StatelessWidget {
  const _SavedItemsList({required this.items});

  final List<SavedItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No saved offers yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            title: Text(item.title),
            subtitle: Text(item.subtitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              if (item.offerId != null) {
                context.push('/offer/${item.offerId}');
              } else if (item.shopId != null) {
                context.push('/shop/${item.shopId}');
              }
            },
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemCount: items.length,
    );
  }
}
