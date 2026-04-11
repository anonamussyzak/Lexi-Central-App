import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/providers/discord_provider.dart';
import 'widgets/message_list.dart';
import 'widgets/server_channel_selector.dart';

class DiscordScreen extends ConsumerStatefulWidget {
  const DiscordScreen({super.key});

  @override
  ConsumerState<DiscordScreen> createState() => _DiscordScreenState();
}

class _DiscordScreenState extends ConsumerState<DiscordScreen> {
  @override
  Widget build(BuildContext context) {
    final discordState = ref.watch(discordProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.discord_outlined,
              color: const Color(0xFF5865F2),
            ),
            const SizedBox(width: 12),
            const Text('Discord Feed'),
          ],
        ),
        centerTitle: false,
        actions: [
          if (discordState.isConfigured)
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, ref),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('Refresh'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'disconnect',
                  child: Row(
                    children: [
                      Icon(Icons.link_off),
                      SizedBox(width: 8),
                      Text('Disconnect'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Server and channel selector
          if (discordState.connectionMethod == 'bot')
            const ServerChannelSelector(),
          
          // Messages list
          Expanded(
            child: Stack(
              children: [
                const MessageList(),
                
                // Error snackbar
                if (discordState.error != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                discordState.error!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                            IconButton(
                              onPressed: () => ref.read(discordProvider.notifier).clearError(),
                              icon: Icon(Icons.close, color: Colors.red.shade700),
                            ),
                          ],
                        ),
                      ),
                    ).animate().slideY(begin: -1, duration: 300.ms),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, WidgetRef ref) {
    switch (action) {
      case 'refresh':
        ref.read(discordProvider.notifier).refreshMessages();
        break;
      case 'disconnect':
        _showDisconnectDialog(ref);
        break;
    }
  }

  void _showDisconnectDialog(WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Discord'),
        content: const Text('Are you sure you want to disconnect from Discord?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(discordProvider.notifier).disconnect();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}
