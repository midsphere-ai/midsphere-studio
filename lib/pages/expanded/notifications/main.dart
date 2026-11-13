import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/domain/entities/cms/tutorial_blog.dart';
import 'package:flutter_client/logics/domain/usecases/cms/cms_usecase.dart';
import 'package:flutter_client/widgets/animations/animations.dart';
import 'package:flutter_client/widgets/backgrounds/constrained_box.dart';
import 'package:flutter_client/widgets/builders/item_builder_list.dart';

import 'components/blog_detail.dart';
import 'components/blog_item.dart';

/// A page that displays all blogs/tutorials as notifications.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  TutorialBlog? _selectedBlog;
  bool _isLoadingContent = false;
  String? _blogContent;

  @override
  Widget build(BuildContext context) {
    return LimitedWindowBox(
      customWidth: 900,
      child: AnimatedSwitcher(
        duration: AnimationConstants.contentSwitchSlow,
        switchInCurve: AnimationConstants.entranceCurve,
        switchOutCurve: AnimationConstants.exitCurve,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.02, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _selectedBlog != null
            ? BlogDetailView(
                key: ValueKey('detail_${_selectedBlog!.id}'),
                blog: _selectedBlog!,
                content: _blogContent,
                isLoading: _isLoadingContent,
                onBack: _closeBlogDetail,
              )
            : _buildBlogList(),
      ),
    );
  }

  Widget _buildBlogList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const Divider(),
        const Gap(16),
        Expanded(
          child: ItemBuilderBloc(
            blocKey: 'notificationBlogs',
            paginated: true,
            dataSource: (repo) => CMS.getTutorialInfo(repo: repo),
            onDataEmpty: "No updates available",
            onError: "Error loading updates",
            placeHolderItems: List.generate(
              3,
              (index) => {
                "id": "load",
                "title": "Loading...",
                "subtitle": "",
                "date_created": DateTime.now().toIso8601String(),
              },
            ),
            item: (data) {
              if (data is TutorialBlog) {
                return BlogItemCard(
                  blog: data,
                  onTap: () => _openBlog(data),
                );
              }

              if (data['id'] == 'load') {
                return const BlogItemLoading();
              }

              final blog = TutorialBlog.fromJson(data);
              return BlogItemCard(
                blog: blog,
                onTap: () => _openBlog(blog),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What's New").h3,
          const Gap(4),
          Text(
            "Stay updated with the latest features, tutorials, and announcements",
          ).muted,
        ],
      ),
    );
  }

  Future<void> _openBlog(TutorialBlog blog) async {
    setState(() {
      _selectedBlog = blog;
      _isLoadingContent = true;
      _blogContent = null;
    });

    try {
      final result = await CMS.getTutorialData(title: blog.title);
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _blogContent = result['markdownText'] ?? blog.markdownText;
          _isLoadingContent = false;
        });
      } else {
        setState(() {
          _blogContent = blog.markdownText;
          _isLoadingContent = false;
        });
      }
    } catch (e) {
      setState(() {
        _blogContent = blog.markdownText;
        _isLoadingContent = false;
      });
    }
  }

  void _closeBlogDetail() {
    setState(() {
      _selectedBlog = null;
      _blogContent = null;
    });
  }
}
