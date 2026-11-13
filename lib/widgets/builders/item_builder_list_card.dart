import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/builders/card_builder.dart';

import '../../logics/data/helpers/general_utils.dart';
import '../../logics/domain/blocs/simple/simple_bloc.dart';
import '../../logics/domain/entities/base/repo.dart';
import '../animations/animations.dart';
import '../state/simple_bloc.dart';

class ItemBuilderBlocCard extends StatefulWidget {
  final String blocKey;
  final bool paginated;
  final double customHeight;
  final double? customWidth;
  final Function dataSource;
  final Map dataSourceArgs;
  final Function item;
  final String onError;
  final String onDataEmpty;
  final List placeHolderItems;
  final bool shrinkWrap;
  /// Whether to animate grid items with staggered entrance. Default: true.
  final bool animateItems;
  /// When true, enables infinite scroll (scroll-to-load) pagination.
  /// Items accumulate as user scrolls. Default: false.
  final bool infiniteScroll;
  /// Distance from bottom (in pixels) to trigger loading more items.
  /// Only used when infiniteScroll is true. Default: 200.0.
  final double loadMoreThreshold;
  const ItemBuilderBlocCard({
    super.key,
    required this.blocKey,
    this.paginated = false,
    this.customHeight = 180,
    this.customWidth,
    required this.dataSource,
    required this.dataSourceArgs,
    required this.item,
    required this.onError,
    required this.onDataEmpty,
    required this.placeHolderItems,
    this.shrinkWrap = false,
    this.animateItems = true,
    this.infiniteScroll = true,
    this.loadMoreThreshold = 200.0,
  });

  @override
  State<ItemBuilderBlocCard> createState() => _ItemBuilderBlocCardState();
}

class _ItemBuilderBlocCardState extends State<ItemBuilderBlocCard> {
  BaseRepository repo = BaseRepository();
  final ValueNotifier<bool> _isLoadingMore = ValueNotifier(false);
  ScrollPosition? _parentScrollPosition;

  @override
  void initState() {
    repo.pageSize = 32;
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

  /// Convert map keys to Symbol map for Function.apply
  Map<Symbol, dynamic> _convertToSymbolMap(Map<dynamic, dynamic> normalMap) {
    Map<Symbol, dynamic> symbolMap = {};
    normalMap.forEach((key, value) {
      String camelCaseKey = key.toString().replaceAllMapped(
        RegExp(r'_([a-z])'),
        (match) => match.group(1)!.toUpperCase(),
      );
      var processedValue = value;
      if (value is List) {
        processedValue = List<dynamic>.from(value);
      }
      symbolMap[Symbol(camelCaseKey)] = processedValue;
    });
    return symbolMap;
  }

  Future<void> _loadMore() async {
    if (!repo.canLoadMore || _isLoadingMore.value) return;

    _isLoadingMore.value = true;
    repo.isLoadingMore = true;

    final Map<dynamic, dynamic> args = {'repo': repo};
    args.addAll(widget.dataSourceArgs);
    final symbolArgs = _convertToSymbolMap(args);

    await Function.apply(widget.dataSource, [], symbolArgs);

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
          successWidgetBuilder: _renderItems,
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
            final Map<dynamic, dynamic> args = {'repo': repo};
            args.addAll(widget.dataSourceArgs);
            bloc.run(
              function: widget.dataSource,
              args: args,
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

  Widget _renderItems(data) {
    data.removeDuplicates();
    if (data.items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.onDataEmpty, textAlign: TextAlign.center).small.muted,
        ],
      );
    }

    // Infinite scroll mode for grid
    if (widget.infiniteScroll) {
      return _buildInfiniteScrollGrid(data);
    }

    final cardBuilder = CardBuilder(
      customHeight: widget.customHeight,
      customWidth: widget.customWidth,
      items: data.items,
      animateItems: widget.animateItems,
      builder: (context, index) {
        final item = data.items[index];
        return widget.item(item);
      },
    );

    return Stack(
      children: [
        Column(
          mainAxisSize: widget.shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
          children: [
            widget.shrinkWrap ? cardBuilder : Expanded(child: cardBuilder),
            if (widget.paginated)
              Column(
                children: [
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildPagination(data),
                  ),
                ],
              )
          ],
        ),
      ],
    );
  }

  Widget _buildInfiniteScrollGrid(dynamic data) {
    const double spacing = 8;
    const double crossAxisSpacing = spacing;
    const double mainAxisSpacing = spacing;
    final double mainAxisExtent = widget.customHeight;
    final double maxCrossAxisExtent = MediaQuery.of(context).size.width < 801
        ? 800
        : (widget.customWidth ?? 300);

    final delegate = SliverGridDelegateWithMaxCrossAxisExtent(
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      mainAxisExtent: mainAxisExtent,
      maxCrossAxisExtent: maxCrossAxisExtent,
      childAspectRatio: 4.6,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: delegate,
      itemCount: data.items.length,
      itemBuilder: (context, index) {
        final item = data.items[index];
        final child = widget.item(item);
        if (widget.animateItems) {
          return AnimatedGridItem(
            index: index,
            child: child,
          );
        }
        return child;
      },
    );
  }

  Widget _buildPagination(BaseRepository data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Pagination(
        showLabel: true,
        page: data.currentPage,
        totalPages: Toolkit.calculateTotalPages(data.maxCount, repo.pageSize),
        onPageChanged: (value) {
          repo.reset();
          repo.currentPage = value;
          final Map<dynamic, dynamic> args = {'repo': repo};
          args.addAll(widget.dataSourceArgs);
          SimpleBlocWidget.getInstance(ValueKey(widget.blocKey)).run(
            function: widget.dataSource,
            args: args,
            errorType: ErrorType.widget,
            successType: SuccessType.widget,
          );
        },
        maxPages: 5,
      ),
    );
  }

  Widget _placeHolder() {
    // When infiniteScroll is true, use shrinkWrap behavior to avoid Expanded in unbounded context
    final useShrinkWrap = widget.shrinkWrap || widget.infiniteScroll;

    final cardBuilder = CardBuilder(
      customHeight: widget.customHeight,
      customWidth: widget.customWidth,
      items: widget.placeHolderItems,
      builder: (context, index) {
        final item = widget.placeHolderItems[index];
        return widget.item(item);
      },
    );

    return Column(
      mainAxisSize: useShrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      children: [
        useShrinkWrap ? cardBuilder : Expanded(child: cardBuilder),
      ],
    );
  }
}
