import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html;
import '../models/notes_models.dart';

class LinkPreviewService {
  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxImageSize = 1024 * 1024; // 1MB

  final Dio _dio = Dio();

  LinkPreviewService() {
    _dio.options.connectTimeout = _timeout;
    _dio.options.receiveTimeout = _timeout;
  }

  Future<LinkPreview> generatePreview(String url) async {
    try {
      // Fetch the HTML content
      final response = await _dio.get(url);
      
      if (response.statusCode != 200) {
        return _createErrorPreview(url);
      }

      final document = html.parse(response.data);
      
      // Extract meta information
      final title = _extractTitle(document, url);
      final description = _extractDescription(document);
      final imageUrl = _extractImageUrl(document, url);
      final faviconUrl = _extractFaviconUrl(document, url);
      final domain = _extractDomain(url);

      return LinkPreview(
        title: title,
        description: description,
        imageUrl: imageUrl,
        faviconUrl: faviconUrl,
        domain: domain,
        isValid: true,
      );

    } catch (e) {
      return _createErrorPreview(url);
    }
  }

  String _extractTitle(html.Document document, String url) {
    // Try Open Graph title first
    final ogTitle = _getMetaContent(document, 'property', 'og:title');
    if (ogTitle.isNotEmpty) return ogTitle;

    // Try Twitter title
    final twitterTitle = _getMetaContent(document, 'name', 'twitter:title');
    if (twitterTitle.isNotEmpty) return twitterTitle;

    // Try regular title tag
    final titleElement = document.querySelector('title');
    if (titleElement != null && titleElement.text.isNotEmpty) {
      return titleElement.text.trim();
    }

    // Try h1 tag
    final h1Element = document.querySelector('h1');
    if (h1Element != null && h1Element.text.isNotEmpty) {
      return h1Element.text.trim();
    }

    // Fallback to domain
    return _extractDomain(url);
  }

  String _extractDescription(html.Document document) {
    // Try Open Graph description first
    final ogDescription = _getMetaContent(document, 'property', 'og:description');
    if (ogDescription.isNotEmpty) return ogDescription;

    // Try Twitter description
    final twitterDescription = _getMetaContent(document, 'name', 'twitter:description');
    if (twitterDescription.isNotEmpty) return twitterDescription;

    // Try meta description
    final metaDescription = _getMetaContent(document, 'name', 'description');
    if (metaDescription.isNotEmpty) return metaDescription;

    // Try to extract first paragraph
    final firstParagraph = document.querySelector('p');
    if (firstParagraph != null && firstParagraph.text.isNotEmpty) {
      final text = firstParagraph.text.trim();
      return text.length > 200 ? '${text.substring(0, 200)}...' : text;
    }

    return '';
  }

  String? _extractImageUrl(html.Document document, String baseUrl) {
    // Try Open Graph image first
    final ogImage = _getMetaContent(document, 'property', 'og:image');
    if (ogImage.isNotEmpty) {
      return _resolveUrl(ogImage, baseUrl);
    }

    // Try Twitter image
    final twitterImage = _getMetaContent(document, 'name', 'twitter:image');
    if (twitterImage.isNotEmpty) {
      return _resolveUrl(twitterImage, baseUrl);
    }

    // Try to find the first suitable image in the content
    final images = document.querySelectorAll('img');
    for (final img in images) {
      final src = img.attributes['src'];
      if (src != null && src.isNotEmpty) {
        final fullUrl = _resolveUrl(src, baseUrl);
        
        // Basic image size check (skip very small images)
        if (_isLikelyContentImage(img)) {
          return fullUrl;
        }
      }
    }

    return null;
  }

  String? _extractFaviconUrl(html.Document document, String baseUrl) {
    // Try standard favicon link
    final faviconLink = document.querySelector('link[rel="icon"], link[rel="shortcut icon"]');
    if (faviconLink != null) {
      final href = faviconLink.attributes['href'];
      if (href != null && href.isNotEmpty) {
        return _resolveUrl(href, baseUrl);
      }
    }

    // Try default favicon location
    final domain = _extractDomain(baseUrl);
    return 'https://$domain/favicon.ico';
  }

  String _getMetaContent(html.Document document, String attribute, String value) {
    final meta = document.querySelector('meta[$attribute="$value"]');
    return meta?.attributes['content']?.trim() ?? '';
  }

  String _resolveUrl(String url, String baseUrl) {
    try {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
      }
      
      final baseUri = Uri.parse(baseUrl);
      final resolvedUri = baseUri.resolve(url);
      return resolvedUri.toString();
    } catch (e) {
      return url;
    }
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return url;
    }
  }

  bool _isLikelyContentImage(html.Element imgElement) {
    final src = imgElement.attributes['src'] ?? '';
    final width = imgElement.attributes['width'];
    final height = imgElement.attributes['height'];
    final alt = imgElement.attributes['alt'] ?? '';
    
    // Skip very small images (likely icons)
    if (width != null && height != null) {
      final w = int.tryParse(width);
      final h = int.tryParse(height);
      if (w != null && h != null && (w < 100 || h < 100)) {
        return false;
      }
    }
    
    // Skip common non-content image patterns
    if (src.contains('icon') || 
        src.contains('logo') || 
        src.contains('avatar') ||
        src.contains('button') ||
        src.contains('spinner')) {
      return false;
    }
    
    // Prefer images with meaningful alt text
    if (alt.isNotEmpty && alt.length > 10) {
      return true;
    }
    
    return true;
  }

  LinkPreview _createErrorPreview(String url) {
    final domain = _extractDomain(url);
    
    return LinkPreview(
      title: domain,
      description: 'Unable to load preview for this link',
      domain: domain,
      isValid: false,
    );
  }

  Future<bool> _isValidImageUrl(String imageUrl) async {
    try {
      final response = await _dio.head(imageUrl);
      
      if (response.statusCode != 200) {
        return false;
      }
      
      final contentType = response.headers['content-type']?.first ?? '';
      if (!contentType.startsWith('image/')) {
        return false;
      }
      
      final contentLength = response.headers['content-length']?.first;
      if (contentLength != null) {
        final size = int.tryParse(contentLength) ?? 0;
        if (size > _maxImageSize) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getOptimizedImageUrl(String imageUrl) async {
    // In a real implementation, you might use an image optimization service
    // For now, we'll just validate the image URL
    final isValid = await _isValidImageUrl(imageUrl);
    return isValid ? imageUrl : null;
  }

  // Batch preview generation for multiple links
  Future<List<LinkPreview>> generateBatchPreviews(List<String> urls) async {
    final futures = urls.map((url) => generatePreview(url));
    return Future.wait(futures);
  }

  // Cache management (simplified version)
  final Map<String, LinkPreview> _previewCache = {};

  Future<LinkPreview> getCachedPreview(String url) async {
    if (_previewCache.containsKey(url)) {
      return _previewCache[url]!;
    }
    
    final preview = await generatePreview(url);
    _previewCache[url] = preview;
    return preview;
  }

  void clearCache() {
    _previewCache.clear();
  }

  // Extract additional metadata for enhanced previews
  Map<String, dynamic> extractAdditionalMetadata(html.Document document) {
    final metadata = <String, dynamic>{};
    
    // Extract author
    final author = _getMetaContent(document, 'name', 'author');
    if (author.isNotEmpty) {
      metadata['author'] = author;
    }
    
    // Extract published date
    final publishedDate = _getMetaContent(document, 'property', 'article:published_time');
    if (publishedDate.isNotEmpty) {
      metadata['publishedDate'] = publishedDate;
    }
    
    // Extract site name
    final siteName = _getMetaContent(document, 'property', 'og:site_name');
    if (siteName.isNotEmpty) {
      metadata['siteName'] = siteName;
    }
    
    // Extract language
    final language = _getMetaContent(document, 'html', 'lang');
    if (language.isNotEmpty) {
      metadata['language'] = language;
    }
    
    // Extract keywords
    final keywords = _getMetaContent(document, 'name', 'keywords');
    if (keywords.isNotEmpty) {
      metadata['keywords'] = keywords.split(',').map((k) => k.trim()).toList();
    }
    
    return metadata;
  }
}
