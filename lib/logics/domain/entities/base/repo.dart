import 'base.dart';

class BaseRepository {
  List<BaseModel> items = [];
  int currentPage = 1;
  int pageSize = 500;
  int maxCount = -1;
  int totalPages = 1;
  bool isLoadingMore = false;
  bool hasReachedMax = false;
  String? lastError;
  /// When true, new items are appended to existing items (for infinite scroll).
  /// When false, items are replaced on each fetch (default behavior).
  bool accumulateItems = false;

  void removeDuplicates() {
    final seen = <String>{};
    items.retainWhere((item) {
      return seen.add(item.id);
    });
  }

  void sort() {
    items.sort((a, b) => a.dateCreated.compareTo(b.dateCreated));
  }

  bool get canLoadMore => !hasReachedMax && !isLoadingMore && currentPage <= totalPages;

  void setLoadingMore(bool loading) {
    isLoadingMore = loading;
  }

  void markReachedMax() {
    hasReachedMax = true;
  }

  /// Appends new items to the existing list (for infinite scroll mode).
  void appendItems(List<BaseModel> newItems) {
    items.addAll(newItems);
  }

  /// Updates hasReachedMax based on current state.
  /// Called after fetching to determine if more data is available.
  void updateHasReachedMax() {
    if (maxCount != -1 && items.length >= maxCount) {
      hasReachedMax = true;
    } else if (currentPage > totalPages) {
      hasReachedMax = true;
    }
  }

  void reset() {
    items.clear();
    currentPage = 1;
    isLoadingMore = false;
    hasReachedMax = false;
    lastError = null;
    accumulateItems = false;
  }
}
