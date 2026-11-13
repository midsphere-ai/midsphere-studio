import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/domain/entities/cms/tutorial_blog.dart';
import 'package:flutter_client/widgets/animations/animations.dart';
import 'package:intl/intl.dart';

import 'blog_thumbnail.dart';

/// A card widget displaying a single blog/tutorial item.
class BlogItemCard extends StatelessWidget {
  final TutorialBlog blog;
  final VoidCallback onTap;

  const BlogItemCard({
    super.key,
    required this.blog,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: HoverScaleWithChevron(
        hoverScale: AnimationConstants.hoverScaleSubtle,
        child: GestureDetector(
          onTap: onTap,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlogThumbnail(imageUrl: blog.image),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          blog.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (blog.subtitle != null && blog.subtitle!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              blog.subtitle!,
                              style: TextStyle(
                                color: scheme.mutedForeground,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const Gap(8),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 12,
                              color: scheme.mutedForeground,
                            ),
                            const Gap(4),
                            Text(
                              dateFormat.format(blog.dateCreated),
                              style: TextStyle(
                                color: scheme.mutedForeground,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedChevron(
                    icon: LucideIcons.chevronRight,
                    size: 20,
                    color: scheme.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A loading placeholder for blog items.
class BlogItemLoading extends StatelessWidget {
  const BlogItemLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: ListTile(
          title: Container(
            height: 16,
            width: 200,
            decoration: BoxDecoration(
              color: scheme.muted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          subtitle: Container(
            height: 12,
            width: 150,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: scheme.muted.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
