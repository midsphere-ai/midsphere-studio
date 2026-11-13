import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/domain/entities/cms/tutorial_blog.dart';
import 'package:flutter_client/packages/widget/markdown.dart' as md;
import 'package:flutter_client/widgets/animations/animations.dart';
import 'package:intl/intl.dart';

import 'blog_thumbnail.dart';

/// A detailed view for reading a single blog post.
class BlogDetailView extends StatelessWidget {
  final TutorialBlog blog;
  final String? content;
  final bool isLoading;
  final VoidCallback onBack;

  const BlogDetailView({
    super.key,
    required this.blog,
    required this.content,
    required this.isLoading,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const Divider(),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 0),
                        child: BlogDetailImage(imageUrl: blog.image),
                      ),
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 50),
                        child: Text(blog.title, textAlign: TextAlign.center).h1,
                      ),
                      const Gap(8),
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 100),
                        child: Text(blog.subtitle ?? "", textAlign: TextAlign.center).h4.muted,
                      ),
                      const Gap(16),
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 150),
                        child: _buildDateRow(scheme, dateFormat),
                      ),
                      const Gap(24),
                      const Divider(),
                      const Gap(16),
                      FadeSlideTransition(
                        delay: const Duration(milliseconds: 200),
                        child: _buildContent(),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: Row(
        children: [
          IconButton.ghost(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: onBack,
          ),
          const Gap(8),
          Text("Back to updates").muted,
        ],
      ),
    );
  }

  Widget _buildDateRow(ColorScheme scheme, DateFormat dateFormat) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.calendar, size: 14, color: scheme.mutedForeground),
        const Gap(6),
        Text(dateFormat.format(blog.dateCreated)).muted,
      ],
    );
  }

  Widget _buildContent() {
    if (content != null && content!.isNotEmpty) {
      return md.MarkdownWidget(data: content!, shrinkWrap: true);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text("No content available").muted,
      ),
    );
  }
}
