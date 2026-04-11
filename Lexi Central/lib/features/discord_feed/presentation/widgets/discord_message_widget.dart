import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../data/models/discord_models.dart';

class DiscordMessageWidget extends StatelessWidget {
  final DiscordMessage message;
  final VoidCallback? onTap;

  const DiscordMessageWidget({
    required this.message,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            // Header with user info and timestamp
            _buildHeader(context),
            
            const SizedBox(height: 8),
            
            // Message content
            _buildContent(context),
            
            // Attachments
            if (message.hasAttachments) ...[
              const SizedBox(height: 8),
              _buildAttachments(context),
            ],
            
            // Embeds
            if (message.hasEmbeds) ...[
              const SizedBox(height: 8),
              _buildEmbeds(context),
            ],
            
            // Reactions
            if (message.hasReactions) ...[
              const SizedBox(height: 8),
              _buildReactions(context),
            ],
          ],
        ),
      ).animate().slideX(begin: -0.1, duration: 300.ms).fadeIn(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // User avatar
        CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: message.author.avatar != null
              ? ClipOval(
                  child: Image.network(
                    'https://cdn.discordapp.com/avatars/${message.author.id}/${message.author.avatar}.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        message.author.displayName.isNotEmpty
                            ? message.author.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                )
              : Text(
                  message.author.displayName.isNotEmpty
                      ? message.author.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
        
        const SizedBox(width: 8),
        
        // Username and discriminator
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    message.author.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (message.author.bot == true) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5865F2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'BOT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                message.author.fullTag,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        
        // Timestamp
        Text(
          _formatTimestamp(message.timestamp),
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
        
        if (message.isEdited) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.edit,
            size: 12,
            color: Colors.grey.shade500,
          ),
        ],
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (message.content.isEmpty) {
      return const SizedBox.shrink();
    }

    // Check if content contains markdown
    final hasMarkdown = message.content.contains('**') ||
                       message.content.contains('*') ||
                       message.content.contains('`') ||
                       message.content.contains('#') ||
                       message.content.contains('[');

    if (hasMarkdown) {
      return MarkdownBody(
        data: message.content,
        styleSheet: MarkdownStyleSheet(
          p: Theme.of(context).textTheme.bodyMedium,
          code: TextStyle(
            backgroundColor: Colors.grey.shade200,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
          codeblockDecoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
      );
    }

    return Text(
      message.content,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildAttachments(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: message.attachments.map((attachment) {
        return _buildAttachment(context, attachment);
      }).toList(),
    );
  }

  Widget _buildAttachment(BuildContext context, DiscordAttachment attachment) {
    if (attachment.isImage) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          overflow: HiddenOverflowMode,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            attachment.url!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFileAttachment(context, attachment);
            },
          ),
        ),
      );
    }

    return _buildFileAttachment(context, attachment);
  }

  Widget _buildFileAttachment(BuildContext context, DiscordAttachment attachment) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            attachment.isVideo ? Icons.video_file : Icons.attach_file,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.filename,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (attachment.size != null)
                  Text(
                    _formatFileSize(attachment.size!),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmbeds(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: message.embeds.map((embed) {
        return _buildEmbed(context, embed);
      }).toList(),
    );
  }

  Widget _buildEmbed(BuildContext context, DiscordEmbed embed) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: embed.color != null 
              ? Color(int.parse(embed.color!))
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (embed.title != null)
            Text(
              embed.title!,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          
          if (embed.description != null) ...[
            const SizedBox(height: 4),
            Text(
              embed.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          
          if (embed.image != null && embed.image!.url != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                embed.image!.url!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          
          if (embed.footer != null) ...[
            const SizedBox(height: 8),
            Text(
              embed.footer!.text,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReactions(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: message.reactions.map((reaction) {
        return _buildReaction(context, reaction);
      }).toList(),
    );
  }

  Widget _buildReaction(BuildContext context, DiscordReaction reaction) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: reaction.me 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: reaction.me 
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reaction.emoji.isCustom && reaction.emoji.imageUrl != null)
            Image.network(
              reaction.emoji.imageUrl!,
              width: 16,
              height: 16,
            )
          else
            Text(
              reaction.emoji.name,
              style: const TextStyle(fontSize: 14),
            ),
          
          const SizedBox(width: 4),
          Text(
            '${reaction.count}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: reaction.me ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
