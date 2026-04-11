import 'package:equatable/equatable.dart';

class DiscordServer extends Equatable {
  final String id;
  final String name;
  final String icon;
  final List<DiscordChannel> channels;

  const DiscordServer({
    required this.id,
    required this.name,
    required this.icon,
    required this.channels,
  });

  @override
  List<Object?> get props => [id, name, icon, channels];
}

class DiscordChannel extends Equatable {
  final String id;
  final String name;
  final String type; // 'text', 'voice', etc.
  final String? topic;
  final int? position;

  const DiscordChannel({
    required this.id,
    required this.name,
    required this.type,
    this.topic,
    this.position,
  });

  @override
  List<Object?> get props => [id, name, type, topic, position];
}

class DiscordMessage extends Equatable {
  final String id;
  final String channelId;
  final DiscordUser author;
  final String content;
  final DateTime timestamp;
  final DateTime? editedTimestamp;
  final List<DiscordAttachment> attachments;
  final List<DiscordEmbed> embeds;
  final List<DiscordReaction> reactions;
  final MessageType type;

  const DiscordMessage({
    required this.id,
    required this.channelId,
    required this.author,
    required this.content,
    required this.timestamp,
    this.editedTimestamp,
    this.attachments = const [],
    this.embeds = const [],
    this.reactions = const [],
    this.type = MessageType.defaultMessage,
  });

  bool get hasAttachments => attachments.isNotEmpty;
  bool get hasEmbeds => embeds.isNotEmpty;
  bool get hasReactions => reactions.isNotEmpty;
  bool get isEdited => editedTimestamp != null;

  @override
  List<Object?> get props => [
        id,
        channelId,
        author,
        content,
        timestamp,
        editedTimestamp,
        attachments,
        embeds,
        reactions,
        type,
      ];
}

class DiscordUser extends Equatable {
  final String id;
  final String username;
  final String discriminator;
  final String? avatar;
  final bool? bot;
  final String? globalName;

  const DiscordUser({
    required this.id,
    required this.username,
    required this.discriminator,
    this.avatar,
    this.bot,
    this.globalName,
  });

  String get displayName => globalName ?? username;
  String get fullTag => '$username#$discriminator';

  @override
  List<Object?> get props => [
        id,
        username,
        discriminator,
        avatar,
        bot,
        globalName,
      ];
}

class DiscordAttachment extends Equatable {
  final String id;
  final String filename;
  final String? url;
  final String? contentType;
  final int? size;
  final String? proxyUrl;

  const DiscordAttachment({
    required this.id,
    required this.filename,
    this.url,
    this.contentType,
    this.size,
    this.proxyUrl,
  });

  bool get isImage => contentType?.startsWith('image/') ?? false;
  bool get isVideo => contentType?.startsWith('video/') ?? false;

  @override
  List<Object?> get props => [
        id,
        filename,
        url,
        contentType,
        size,
        proxyUrl,
      ];
}

class DiscordEmbed extends Equatable {
  final String? title;
  final String? description;
  final String? url;
  final String? type;
  final EmbedImage? image;
  final EmbedThumbnail? thumbnail;
  final EmbedFooter? footer;
  final String? color;

  const DiscordEmbed({
    this.title,
    this.description,
    this.url,
    this.type,
    this.image,
    this.thumbnail,
    this.footer,
    this.color,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        url,
        type,
        image,
        thumbnail,
        footer,
        color,
      ];
}

class EmbedImage extends Equatable {
  final String? url;
  final String? proxyUrl;
  final int? width;
  final int? height;

  const EmbedImage({
    this.url,
    this.proxyUrl,
    this.width,
    this.height,
  });

  @override
  List<Object?> get props => [url, proxyUrl, width, height];
}

class EmbedThumbnail extends Equatable {
  final String? url;
  final String? proxyUrl;
  final int? width;
  final int? height;

  const EmbedThumbnail({
    this.url,
    this.proxyUrl,
    this.width,
    this.height,
  });

  @override
  List<Object?> get props => [url, proxyUrl, width, height];
}

class EmbedFooter extends Equatable {
  final String text;
  final String? iconUrl;
  final String? proxyIconUrl;

  const EmbedFooter({
    required this.text,
    this.iconUrl,
    this.proxyIconUrl,
  });

  @override
  List<Object?> get props => [text, iconUrl, proxyIconUrl];
}

class DiscordReaction extends Equatable {
  final DiscordEmoji emoji;
  final int count;
  final bool me;

  const DiscordReaction({
    required this.emoji,
    required this.count,
    required this.me,
  });

  @override
  List<Object?> get props => [emoji, count, me];
}

class DiscordEmoji extends Equatable {
  final String? id;
  final String name;
  final bool? animated;
  final String? imageUrl;

  const DiscordEmoji({
    this.id,
    required this.name,
    this.animated,
    this.imageUrl,
  });

  bool get isCustom => id != null;

  @override
  List<Object?> get props => [id, name, animated, imageUrl];
}

enum MessageType {
  defaultMessage,
  recipientAdd,
  recipientRemove,
  call,
  channelNameChange,
  channelIconChange,
  pinsAdd,
  newMember,
  guildMemberJoin,
  userPremiumGuildSubscription,
  userPremiumGuildSubscriptionTier1,
  userPremiumGuildSubscriptionTier2,
  userPremiumGuildSubscriptionTier3,
  channelFollowAdd,
  guildDiscoveryDisqualified,
  guildDiscoveryRequalified,
  guildDiscoveryGracePeriodInitialWarning,
  guildDiscoveryGracePeriodFinalWarning,
  threadCreated,
  inlineReply,
  chatInputCommand,
  threadStarterMessage,
  guildInviteReminder,
  contextMenuCommand,
  autoModerationAction,
  roleSubscriptionPurchase,
  interactionPremiumUpsell,
  stageStart,
  stageEnd,
  stageSpeaker,
  stageTopic,
  guildApplicationPremiumSubscription,
}
