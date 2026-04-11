import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/discord_models.dart';
import '../../domain/providers/discord_provider.dart';
import 'discord_message_widget.dart';

class MessageList extends ConsumerStatefulWidget {
  const MessageList({super.key});

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 100) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore) return;
    
    final discordNotifier = ref.read(discordProvider.notifier);
    if (discordNotifier.state.isLoading) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    await discordNotifier.loadMoreMessages();
    
    setState(() {
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final discordState = ref.watch(discordProvider);
    final messages = discordState.messages;

    if (!discordState.isConfigured) {
      return _buildNotConfigured();
    }

    if (discordState.selectedChannel == null && discordState.connectionMethod == 'bot') {
      return _buildSelectChannel();
    }

    if (discordState.isLoading && messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFB8F2E6),
        ),
      );
    }

    if (messages.isEmpty) {
      return _buildEmptyMessages();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(discordProvider.notifier).refreshMessages(),
      color: const Color(0xFFB8F2E6),
      child: Column(
        children: [
          // Channel header
          if (discordState.selectedChannel != null)
            _buildChannelHeader(discordState.selectedChannel!),
          
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true, // Show newest at bottom
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: messages.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return _buildLoadingIndicator();
                }
                
                final message = messages[index];
                return DiscordMessageWidget(
                  message: message,
                  onTap: () => _showMessageDetails(message),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotConfigured() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.discord_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ).animate().scale(delay: 200.ms, duration: 600.ms).then().shake(),
          
          const SizedBox(height: 24),
          
          Text(
            'Discord Not Connected',
            style: Theme.of(context).textTheme.displayMedium,
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 16),
          
          Text(
            'Connect to a Discord server to view messages',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),
          
          const SizedBox(height: 32),
          
          ElevatedButton.icon(
            onPressed: () => _showSetupDialog(),
            icon: const Icon(Icons.link),
            label: const Text('Connect Discord'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5865F2),
              foregroundColor: Colors.white,
            ),
          ).animate().fadeIn(delay: 800.ms).scale(),
        ],
      ),
    );
  }

  Widget _buildSelectChannel() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tag_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ).animate().scale(delay: 200.ms, duration: 600.ms),
          
          const SizedBox(height: 24),
          
          Text(
            'Select a Channel',
            style: Theme.of(context).textTheme.displayMedium,
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 16),
          
          Text(
            'Choose a server and channel to view messages',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ).animate().scale(delay: 200.ms, duration: 600.ms),
          
          const SizedBox(height: 24),
          
          Text(
            'No Messages Yet',
            style: Theme.of(context).textTheme.displayMedium,
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 16),
          
          Text(
            'Messages will appear here when they are sent',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildChannelHeader(DiscordChannel channel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.tag,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${channel.name}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (channel.topic != null && channel.topic!.isNotEmpty)
                  Text(
                    channel.topic!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: const Color(0xFFB8F2E6),
          ),
        ),
      ),
    );
  }

  void _showMessageDetails(DiscordMessage message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _MessageDetailsSheet(message: message),
    );
  }

  void _showSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => const DiscordSetupDialog(),
    );
  }
}

class _MessageDetailsSheet extends StatelessWidget {
  final DiscordMessage message;

  const _MessageDetailsSheet({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Message info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  message.author.displayName.isNotEmpty
                      ? message.author.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.author.displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      message.author.fullTag,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Timestamp
          Text(
            'Sent: ${message.timestamp.toString()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          
          if (message.isEdited) ...[
            Text(
              'Edited: ${message.editedTimestamp.toString()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Message ID
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Message ID: ${message.id}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Content
          if (message.content.isNotEmpty) ...[
            Text(
              'Content:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(message.content),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

class DiscordSetupDialog extends ConsumerWidget {
  const DiscordSetupDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Connect Discord'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Choose how you want to connect to Discord:'),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Bot Token'),
            subtitle: const Text('Connect using a Discord bot token'),
            leading: const Icon(Icons.smart_toy),
            onTap: () {
              Navigator.of(context).pop();
              _showBotTokenDialog(context, ref);
            },
          ),
          ListTile(
            title: const Text('Webhook URL'),
            subtitle: const Text('Connect using a webhook URL'),
            leading: const Icon(Icons.link),
            onTap: () {
              Navigator.of(context).pop();
              _showWebhookDialog(context, ref);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _showBotTokenDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Bot Token'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your Discord bot token:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Bot Token',
                hintText: 'Your bot token here...',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            Text(
              '⚠️ Keep your bot token secure and private',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(discordProvider.notifier).configureBot(controller.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showWebhookDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Webhook URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your Discord webhook URL:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Webhook URL',
                hintText: 'https://discord.com/api/webhooks/...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(discordProvider.notifier).configureWebhook(controller.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}
