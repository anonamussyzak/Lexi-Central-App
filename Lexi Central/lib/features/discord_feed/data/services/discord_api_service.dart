import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/discord_models.dart';

class DiscordApiService {
  static const String _baseUrl = 'https://discord.com/api/v10';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  static const String _botTokenKey = 'discord_bot_token';
  static const String _webhookUrlKey = 'discord_webhook_url';
  static const String _connectedServerKey = 'discord_connected_server';
  static const String _connectedChannelKey = 'discord_connected_channel';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  DiscordApiService() {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) => print(object),
    ));
  }

  /// Check if Discord is configured
  Future<bool> isConfigured() async {
    final botToken = await _secureStorage.read(key: _botTokenKey);
    final webhookUrl = await _secureStorage.read(key: _webhookUrlKey);
    return (botToken != null && botToken.isNotEmpty) || 
           (webhookUrl != null && webhookUrl.isNotEmpty);
  }

  /// Get connection method (bot or webhook)
  Future<String> getConnectionMethod() async {
    final botToken = await _secureStorage.read(key: _botTokenKey);
    return botToken != null ? 'bot' : 'webhook';
  }

  /// Configure with bot token
  Future<void> configureBot(String botToken) async {
    try {
      // Validate bot token
      _dio.options.headers['Authorization'] = 'Bot $botToken';
      final response = await _dio.get('/users/@me');
      
      if (response.statusCode == 200) {
        await _secureStorage.write(key: _botTokenKey, value: botToken);
        _dio.options.headers['Authorization'] = 'Bot $botToken';
      } else {
        throw Exception('Invalid bot token');
      }
    } catch (e) {
      throw Exception('Failed to configure bot: $e');
    }
  }

  /// Configure with webhook URL
  Future<void> configureWebhook(String webhookUrl) async {
    try {
      // Validate webhook URL
      final response = await Dio().get(webhookUrl);
      
      if (response.statusCode == 200) {
        await _secureStorage.write(key: _webhookUrlKey, value: webhookUrl);
      } else {
        throw Exception('Invalid webhook URL');
      }
    } catch (e) {
      throw Exception('Failed to configure webhook: $e');
    }
  }

  /// Get user's guilds (servers)
  Future<List<DiscordServer>> getGuilds() async {
    try {
      final response = await _dio.get('/users/@me/guilds');
      
      if (response.statusCode == 200) {
        final guilds = (response.data as List)
            .map((guild) => DiscordServer(
                  id: guild['id'],
                  name: guild['name'],
                  icon: guild['icon'] ?? '',
                  channels: [], // Will be loaded separately
                ))
            .toList();
        return guilds;
      } else {
        throw Exception('Failed to fetch guilds');
      }
    } catch (e) {
      throw Exception('Failed to get guilds: $e');
    }
  }

  /// Get channels for a guild
  Future<List<DiscordChannel>> getGuildChannels(String guildId) async {
    try {
      final response = await _dio.get('/guilds/$guildId/channels');
      
      if (response.statusCode == 200) {
        final channels = (response.data as List)
            .where((channel) => channel['type'] == 0) // Text channels only
            .map((channel) => DiscordChannel(
                  id: channel['id'],
                  name: channel['name'],
                  type: channel['type'].toString(),
                  topic: channel['topic'],
                  position: channel['position'],
                ))
            .toList();
        
        // Sort by position
        channels.sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
        return channels;
      } else {
        throw Exception('Failed to fetch channels');
      }
    } catch (e) {
      throw Exception('Failed to get channels: $e');
    }
  }

  /// Get messages from a channel
  Future<List<DiscordMessage>> getChannelMessages(
    String channelId, {
    int limit = 50,
    String? before,
  }) async {
    try {
      String url = '/channels/$channelId/messages?limit=$limit';
      if (before != null) {
        url += '&before=$before';
      }
      
      final response = await _dio.get(url);
      
      if (response.statusCode == 200) {
        final messages = (response.data as List)
            .map((message) => _parseMessage(message))
            .toList();
        
        // Sort by timestamp (newest first)
        messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return messages;
      } else {
        throw Exception('Failed to fetch messages');
      }
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  /// Get messages from webhook (latest messages)
  Future<List<DiscordMessage>> getWebhookMessages() async {
    try {
      final webhookUrl = await _secureStorage.read(key: _webhookUrlKey);
      if (webhookUrl == null) {
        throw Exception('Webhook not configured');
      }
      
      // Webhook messages are harder to fetch - this is a simplified approach
      // In a real implementation, you might need a different approach
      final response = await Dio().get('$webhookUrl?wait=true');
      
      if (response.statusCode == 200) {
        // Webhook responses are different format, need custom parsing
        return [];
      } else {
        throw Exception('Failed to fetch webhook messages');
      }
    } catch (e) {
      throw Exception('Failed to get webhook messages: $e');
    }
  }

  /// Parse message from API response
  DiscordMessage _parseMessage(Map<String, dynamic> data) {
    return DiscordMessage(
      id: data['id'],
      channelId: data['channel_id'],
      author: _parseUser(data['author']),
      content: data['content'] ?? '',
      timestamp: DateTime.parse(data['timestamp']),
      editedTimestamp: data['edited_timestamp'] != null 
          ? DateTime.parse(data['edited_timestamp']) 
          : null,
      attachments: (data['attachments'] as List? ?? [])
          .map((attachment) => _parseAttachment(attachment))
          .toList(),
      embeds: (data['embeds'] as List? ?? [])
          .map((embed) => _parseEmbed(embed))
          .toList(),
      reactions: (data['reactions'] as List? ?? [])
          .map((reaction) => _parseReaction(reaction))
          .toList(),
      type: MessageType.values.firstWhere(
        (type) => type.name == data['type'].toString(),
        orElse: () => MessageType.defaultMessage,
      ),
    );
  }

  /// Parse user from API response
  DiscordUser _parseUser(Map<String, dynamic> data) {
    return DiscordUser(
      id: data['id'],
      username: data['username'],
      discriminator: data['discriminator'],
      avatar: data['avatar'],
      bot: data['bot'],
      globalName: data['global_name'],
    );
  }

  /// Parse attachment from API response
  DiscordAttachment _parseAttachment(Map<String, dynamic> data) {
    return DiscordAttachment(
      id: data['id'],
      filename: data['filename'],
      url: data['url'],
      contentType: data['content_type'],
      size: data['size'],
      proxyUrl: data['proxy_url'],
    );
  }

  /// Parse embed from API response
  DiscordEmbed _parseEmbed(Map<String, dynamic> data) {
    return DiscordEmbed(
      title: data['title'],
      description: data['description'],
      url: data['url'],
      type: data['type'],
      image: data['image'] != null ? _parseEmbedImage(data['image']) : null,
      thumbnail: data['thumbnail'] != null ? _parseEmbedThumbnail(data['thumbnail']) : null,
      footer: data['footer'] != null ? _parseEmbedFooter(data['footer']) : null,
      color: data['color']?.toString(),
    );
  }

  /// Parse embed image
  EmbedImage? _parseEmbedImage(Map<String, dynamic>? data) {
    if (data == null) return null;
    return EmbedImage(
      url: data['url'],
      proxyUrl: data['proxy_url'],
      width: data['width'],
      height: data['height'],
    );
  }

  /// Parse embed thumbnail
  EmbedThumbnail? _parseEmbedThumbnail(Map<String, dynamic>? data) {
    if (data == null) return null;
    return EmbedThumbnail(
      url: data['url'],
      proxyUrl: data['proxy_url'],
      width: data['width'],
      height: data['height'],
    );
  }

  /// Parse embed footer
  EmbedFooter? _parseEmbedFooter(Map<String, dynamic>? data) {
    if (data == null) return null;
    return EmbedFooter(
      text: data['text'],
      iconUrl: data['icon_url'],
      proxyIconUrl: data['proxy_icon_url'],
    );
  }

  /// Parse reaction
  DiscordReaction _parseReaction(Map<String, dynamic> data) {
    return DiscordReaction(
      emoji: _parseEmoji(data['emoji']),
      count: data['count'],
      me: data['me'],
    );
  }

  /// Parse emoji
  DiscordEmoji _parseEmoji(Map<String, dynamic> data) {
    return DiscordEmoji(
      id: data['id'],
      name: data['name'],
      animated: data['animated'],
      imageUrl: data['id'] != null 
          ? 'https://cdn.discordapp.com/emojis/${data['id']}.${data['animated'] == true ? 'gif' : 'png'}'
          : null,
    );
  }

  /// Save connected server and channel
  Future<void> saveConnection(String serverId, String channelId) async {
    await _secureStorage.write(key: _connectedServerKey, value: serverId);
    await _secureStorage.write(key: _connectedChannelKey, value: channelId);
  }

  /// Get connected server
  Future<String?> getConnectedServer() async {
    return await _secureStorage.read(key: _connectedServerKey);
  }

  /// Get connected channel
  Future<String?> getConnectedChannel() async {
    return await _secureStorage.read(key: _connectedChannelKey);
  }

  /// Clear Discord configuration
  Future<void> clearConfiguration() async {
    await _secureStorage.delete(key: _botTokenKey);
    await _secureStorage.delete(key: _webhookUrlKey);
    await _secureStorage.delete(key: _connectedServerKey);
    await _secureStorage.delete(key: _connectedChannelKey);
  }

  /// Get current authorization header
  Future<String?> getAuthHeader() async {
    final botToken = await _secureStorage.read(key: _botTokenKey);
    if (botToken != null) {
      return 'Bot $botToken';
    }
    return null;
  }
}
