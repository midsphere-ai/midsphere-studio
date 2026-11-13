import 'package:arcane/arcane.dart';

import '../../logics/data/helpers/general_utils.dart';
import '../../logics/domain/blocs/simple/simple_bloc.dart';
import '../../logics/domain/entities/base/repo.dart';
import '../animations/animations.dart';
import '../state/simple_bloc.dart';

class ItemBuilderBloc extends StatefulWidget {
  final String blocKey;
  final bool paginated;
  final Future<dynamic> Function(BaseRepository repo) dataSource;
  final Function item;
  final String onError;
  final String onDataEmpty;
  final List placeHolderItems;
  final BaseRepository? customRepo;
  final ScrollController? customController;
  final Widget Function(dynamic data)? customSuccess;
  /// Whether to animate list items with staggered entrance. Default: true.
  final bool animateItems;
  /// When true, enables infinite scroll (scroll-to-load) pagination.
  /// Items accumulate as user scrolls. Default: false.
  final bool infiniteScroll;
  /// Distance from bottom (in pixels) to trigger loading more items.
  /// Only used when infiniteScroll is true. Default: 200.0.
  final double loadMoreThreshold;
  const ItemBuilderBloc({
    super.key,
    required this.blocKey,
    this.customRepo,
    this.customSuccess,
    this.paginated = false,
    this.customController,
    required this.dataSource,
    required this.item,
    required this.onError,
    required this.onDataEmpty,
    required this.placeHolderItems,
    this.animateItems = true,
    this.infiniteScroll = true,
    this.loadMoreThreshold = 200.0,
  });

  @override
  State<ItemBuilderBloc> createState() => _ItemBuilderBlocState();
}

class _ItemBuilderBlocState extends State<ItemBuilderBloc> {
  late BaseRepository repo;
  final ValueNotifier<bool> _isLoadingMore = ValueNotifier(false);
  ScrollPosition? _parentScrollPosition;

  @override
  void initState() {
    if (widget.customRepo != null) {
      repo = widget.customRepo!;
    } else {
      repo = BaseRepository();
    }
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.infiniteScroll) {
      _detachFromParentScroll();
      _attachToParentScroll();
    }
  }

  @override
  void dispose() {
    _detachFromParentScroll();
    _isLoadingMore.dispose();
    super.dispose();
  }

  void _attachToParentScroll() {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != null) {
      _parentScrollPosition = scrollable.position;
      _parentScrollPosition!.addListener(_onParentScroll);
    }
  }

  void _detachFromParentScroll() {
    _parentScrollPosition?.removeListener(_onParentScroll);
    _parentScrollPosition = null;
  }

  void _onParentScroll() {
    if (!widget.infiniteScroll || _isLoadingMore.value || repo.hasReachedMax) return;
    if (_parentScrollPosition == null) return;

    final position = _parentScrollPosition!;
    if (position.pixels >= position.maxScrollExtent - widget.loadMoreThreshold) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (!repo.canLoadMore || _isLoadingMore.value) return;

    _isLoadingMore.value = true;
    repo.isLoadingMore = true;

    await widget.dataSource(repo);

    if (mounted) {
      _isLoadingMore.value = false;
      repo.isLoadingMore = false;
      setState(() {}); // Trigger rebuild to show new items
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SimpleBlocWidget(
          key: ValueKey(widget.blocKey),
          withoutAnimation: true,
          loadingWidget: _placeHolder().asSkeleton(),
          successWidgetBuilder: widget.customSuccess ?? _renderItems,
          errorWidgetBuilder: (error) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 32),
                Icon(LucideIcons.triangleAlert, size: 64).iconMutedForeground(),
                SizedBox(height: 8),
                Text(
                  "${widget.onError}. If this persists, please report this bug to the mail support@midsphere.ai",
                  textAlign: TextAlign.center,
                ).muted.small,
              ],
            );
          },
          blocInit: (SimpleBloc bloc) {
            repo.reset();
            if (widget.infiniteScroll) {
              repo.accumulateItems = true;
            }
            bloc.run(
              function: ({required BaseRepository repo}) => widget.dataSource(repo),
              args: {'repo': repo},
              errorType: ErrorType.widget,
              successType: SuccessType.widget,
            );
          },
          child: _placeHolder().asSkeleton(),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _isLoadingMore,
          builder: (context, isLoading, child) {
            if (isLoading) {
              return _placeHolder().asSkeleton();
            }
            return SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _renderItems(dynamic data) {
    data.removeDuplicates();
    if (widget.customSuccess != null) {
      widget.customSuccess!(data);
    }

    if (data.items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.onDataEmpty, textAlign: TextAlign.center).small.muted,
        ],
      );
    }

    // Infinite scroll mode
    if (widget.infiniteScroll) {
      return ListView.builder(
        shrinkWrap: true,
        // Nested inside parent scrollable - disable own scrolling to avoid scroll conflicts
        physics: NeverScrollableScrollPhysics(),
        itemCount: data.items.length,
        itemBuilder: (context, index) {
          final item = data.items[index];
          final child = widget.item(item);
          if (widget.animateItems) {
            return AnimatedListItem(
              index: index,
              child: child,
            );
          }
          return child;
        },
      );
    }

    if (!widget.paginated) {
      return Align(
        alignment: Alignment.topCenter,
        child: ListView.builder(
          shrinkWrap: true, // Makes ListView take only the space it needs
          physics: NeverScrollableScrollPhysics(), // Disables inner scrolling
          itemCount: data.items.length,
          itemBuilder: (context, index) {
            final item = data.items[index];
            final child = widget.item(item);
            if (widget.animateItems) {
              return AnimatedListItem(
                index: index,
                child: child,
              );
            }
            return child;
          },
        ),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: ListView.builder(
                shrinkWrap: true, // Makes ListView take only the space it needs
                itemCount: data.items.length,
                itemBuilder: (context, index) {
                  final item = data.items[index];
                  final child = widget.item(item);
                  if (widget.animateItems) {
                    return AnimatedListItem(
                      index: index,
                      child: child,
                    );
                  }
                  return child;
                },
              ),
            ),
            if(widget.paginated) Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                spacing: 8,
                children: [
                  Divider(),
                  _buildPaginationView(data),
                ],
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildPaginationView(BaseRepository data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Pagination(
        page: data.currentPage,
        totalPages: Toolkit.calculateTotalPages(data.maxCount, repo.pageSize),
        onPageChanged: (value) {
          repo.reset();
          repo.currentPage = value;
          SimpleBlocWidget.getInstance(ValueKey(widget.blocKey)).run(
            function: ({required BaseRepository repo}) => widget.dataSource(repo),
            args: {'repo': repo},
            errorType: ErrorType.widget,
            successType: SuccessType.widget,
          );
        },
        maxPages: 3,
      ),
    );
  }

  Widget _placeHolder() {
    return Align(
      alignment: Alignment.topCenter,
      child: ListView.builder(
        shrinkWrap: true, // Makes ListView take only the space it needs
        physics: NeverScrollableScrollPhysics(), // Disables inner scrolling
        itemCount: widget.placeHolderItems.length,
        itemBuilder: (context, index) {
          final item = widget.placeHolderItems[index];
          return widget.item(item);
        },
      ),
    );
  }
}
