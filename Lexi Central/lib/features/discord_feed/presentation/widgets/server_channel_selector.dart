import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/discord_models.dart';
import '../../domain/providers/discord_provider.dart';

class ServerChannelSelector extends ConsumerWidget {
  const ServerChannelSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discordState = ref.watch(discordProvider);
    final discordNotifier = ref.read(discordProvider.notifier);

    if (!discordState.isConfigured) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Server selector
          Expanded(
            child: _buildServerSelector(context, ref, discordState, discordNotifier),
          ),
          
          const SizedBox(width: 16),
          
          // Channel selector
          Expanded(
            child: _buildChannelSelector(context, ref, discordState, discordNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildServerSelector(
    BuildContext context,
    WidgetRef ref,
    DiscordState discordState,
    DiscordNotifier discordNotifier,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.dns,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Server',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: discordState.servers.isEmpty
                ? _buildEmptyServers(context, discordNotifier)
                : _buildServerList(context, ref, discordState, discordNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelSelector(
    BuildContext context,
    WidgetRef ref,
    DiscordState discordState,
    DiscordNotifier discordNotifier,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.tag,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Channel',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: discordState.selectedServer == null
                ? _buildNoServerSelected(context)
                : discordState.channels.isEmpty
                    ? _buildNoChannels(context)
                    : _buildChannelList(context, ref, discordState, discordNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyServers(BuildContext context, DiscordNotifier discordNotifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dns_outlined,
            size: 32,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'No servers',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          TextButton(
            onPressed: discordNotifier.loadServers,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildServerList(
    BuildContext context,
    WidgetRef ref,
    DiscordState discordState,
    DiscordNotifier discordNotifier,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: discordState.servers.length,
      itemBuilder: (context, index) {
        final server = discordState.servers[index];
        final isSelected = discordState.selectedServer?.id == server.id;
        
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: server.icon.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      'https://cdn.discordapp.com/icons/${server.id}/${server.icon}.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          server.name.isNotEmpty ? server.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  )
                : Text(
                    server.name.isNotEmpty ? server.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
          title: Text(
            server.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
          selected: isSelected,
          selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          onTap: () => discordNotifier.selectServer(server),
        ).animate().scale(delay: (index * 50).ms, duration: 200.ms);
      },
    );
  }

  Widget _buildNoServerSelected(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dns_outlined,
            size: 32,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Select a server',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoChannels(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tag_outlined,
            size: 32,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'No channels',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelList(
    BuildContext context,
    WidgetRef ref,
    DiscordState discordState,
    DiscordNotifier discordNotifier,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: discordState.channels.length,
      itemBuilder: (context, index) {
        final channel = discordState.channels[index];
        final isSelected = discordState.selectedChannel?.id == channel.id;
        
        return ListTile(
          dense: true,
          leading: Icon(
            Icons.tag,
            size: 16,
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
          ),
          title: Text(
            '#${channel.name}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
          subtitle: channel.topic != null && channel.topic!.isNotEmpty
              ? Text(
                  channel.topic!,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          selected: isSelected,
          selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          onTap: () => discordNotifier.selectChannel(channel),
        ).animate().scale(delay: (index * 50).ms, duration: 200.ms);
      },
    );
  }
}
