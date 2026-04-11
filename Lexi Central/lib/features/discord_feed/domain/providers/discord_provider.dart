import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/discord_models.dart';
import '../../data/services/discord_api_service.dart';

class DiscordState {
  final bool isConfigured;
  final String connectionMethod;
  final List<DiscordServer> servers;
  final List<DiscordChannel> channels;
  final List<DiscordMessage> messages;
  final DiscordServer? selectedServer;
  final DiscordChannel? selectedChannel;
  final bool isLoading;
  final String? error;

  const DiscordState({
    this.isConfigured = false,
    this.connectionMethod = '',
    this.servers = const [],
    this.channels = const [],
    this.messages = const [],
    this.selectedServer,
    this.selectedChannel,
    this.isLoading = false,
    this.error,
  });

  DiscordState copyWith({
    bool? isConfigured,
    String? connectionMethod,
    List<DiscordServer>? servers,
    List<DiscordChannel>? channels,
    List<DiscordMessage>? messages,
    DiscordServer? selectedServer,
    DiscordChannel? selectedChannel,
    bool? isLoading,
    String? error,
  }) {
    return DiscordState(
      isConfigured: isConfigured ?? this.isConfigured,
      connectionMethod: connectionMethod ?? this.connectionMethod,
      servers: servers ?? this.servers,
      channels: channels ?? this.channels,
      messages: messages ?? this.messages,
      selectedServer: selectedServer ?? this.selectedServer,
      selectedChannel: selectedChannel ?? this.selectedChannel,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class DiscordNotifier extends StateNotifier<DiscordState> {
  final DiscordApiService _apiService;

  DiscordNotifier(this._apiService) : super(const DiscordState()) {
    _initializeDiscord();
  }

  Future<void> _initializeDiscord() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final isConfigured = await _apiService.isConfigured();
      final connectionMethod = await _apiService.getConnectionMethod();
      
      state = state.copyWith(
        isConfigured: isConfigured,
        connectionMethod: connectionMethod,
        isLoading: false,
      );
      
      if (isConfigured) {
        await _loadSavedConnection();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize Discord: ${e.toString()}',
      );
    }
  }

  Future<void> configureBot(String botToken) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _apiService.configureBot(botToken);
      
      state = state.copyWith(
        isConfigured: true,
        connectionMethod: 'bot',
        isLoading: false,
      );
      
      await loadServers();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to configure bot: ${e.toString()}',
      );
    }
  }

  Future<void> configureWebhook(String webhookUrl) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _apiService.configureWebhook(webhookUrl);
      
      state = state.copyWith(
        isConfigured: true,
        connectionMethod: 'webhook',
        isLoading: false,
      );
      
      await loadWebhookMessages();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to configure webhook: ${e.toString()}',
      );
    }
  }

  Future<void> loadServers() async {
    if (!state.isConfigured) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final servers = await _apiService.getGuilds();
      
      state = state.copyWith(
        servers: servers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load servers: ${e.toString()}',
      );
    }
  }

  Future<void> selectServer(DiscordServer server) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final channels = await _apiService.getGuildChannels(server.id);
      
      state = state.copyWith(
        selectedServer: server,
        channels: channels,
        selectedChannel: null,
        messages: [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load channels: ${e.toString()}',
      );
    }
  }

  Future<void> selectChannel(DiscordChannel channel) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final messages = await _apiService.getChannelMessages(channel.id);
      
      // Save connection
      await _apiService.saveConnection(
        state.selectedServer!.id,
        channel.id,
      );
      
      state = state.copyWith(
        selectedChannel: channel,
        messages: messages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load messages: ${e.toString()}',
      );
    }
  }

  Future<void> loadWebhookMessages() async {
    if (state.connectionMethod != 'webhook') return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final messages = await _apiService.getWebhookMessages();
      
      state = state.copyWith(
        messages: messages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load webhook messages: ${e.toString()}',
      );
    }
  }

  Future<void> loadMoreMessages() async {
    if (state.selectedChannel == null || state.messages.isEmpty) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final oldestMessage = state.messages.last;
      final moreMessages = await _apiService.getChannelMessages(
        state.selectedChannel!.id,
        before: oldestMessage.id,
      );
      
      state = state.copyWith(
        messages: [...state.messages, ...moreMessages],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load more messages: ${e.toString()}',
      );
    }
  }

  Future<void> refreshMessages() async {
    if (state.selectedChannel == null) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final messages = await _apiService.getChannelMessages(state.selectedChannel!.id);
      
      state = state.copyWith(
        messages: messages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to refresh messages: ${e.toString()}',
      );
    }
  }

  Future<void> _loadSavedConnection() async {
    try {
      final serverId = await _apiService.getConnectedServer();
      final channelId = await _apiService.getConnectedChannel();
      
      if (serverId != null && channelId != null) {
        await loadServers();
        
        final server = state.servers.where((s) => s.id == serverId).firstOrNull;
        if (server != null) {
          await selectServer(server);
          
          final channel = state.channels.where((c) => c.id == channelId).firstOrNull;
          if (channel != null) {
            await selectChannel(channel);
          }
        }
      }
    } catch (e) {
      // Don't show error for saved connection loading
      print('Failed to load saved connection: $e');
    }
  }

  Future<void> disconnect() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _apiService.clearConfiguration();
      
      state = const DiscordState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to disconnect: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final discordApiServiceProvider = Provider<DiscordApiService>((ref) {
  return DiscordApiService();
});

final discordProvider = StateNotifierProvider<DiscordNotifier, DiscordState>((ref) {
  final apiService = ref.watch(discordApiServiceProvider);
  return DiscordNotifier(apiService);
});

final discordMessagesProvider = Provider<List<DiscordMessage>>((ref) {
  return ref.watch(discordProvider).messages;
});

final discordChannelsProvider = Provider<List<DiscordChannel>>((ref) {
  return ref.watch(discordProvider).channels;
});

final discordServersProvider = Provider<List<DiscordServer>>((ref) {
  return ref.watch(discordProvider).servers;
});
