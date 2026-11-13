import 'package:arcane/arcane.dart';

import '../../../../logics/domain/entities/memory/misc/file.dart';
import '../../../../logics/domain/usecases/memory/memory_usecase.dart';
import '../../../../widgets/builders/item_builder_list_card.dart';
import '../../../../widgets/files/file_card.dart';

class ExpandedFileView extends StatefulWidget {
  final String? searchQuery;
  const ExpandedFileView({super.key, this.searchQuery});

  @override
  State<ExpandedFileView> createState() => _ExpandedFileViewState();
}

class _ExpandedFileViewState extends State<ExpandedFileView> {
  final mockStoredFiles = [
    StoredFile(
      id: "10001",
      owner: 1,
      file: "/uploads/docs/resume.pdf",
      name: "Affan_Resume.pdf",
      size: 2_450_000,
      mimeType: "application/pdf",
      uploadedAt: DateTime.parse("2025-12-20T10:15:30"),
      updatedAt: DateTime.parse("2025-12-21T09:10:12"),
    ),
    StoredFile(
      id: "10002",
      owner: 2,
      file: "/uploads/images/event.jpg",
      name: "College_Event.jpg",
      size: 3_800_500,
      mimeType: "image/jpeg",
      uploadedAt: DateTime.parse("2025-11-05T18:40:10"),
      updatedAt: DateTime.parse("2025-11-05T18:40:10"),
    ),
    StoredFile(
      id: "10003",
      owner: 1,
      file: "/uploads/videos/arrow_demo.mp4",
      name: "Project_Arrow_Demo.mp4",
      size: 125_000_000,
      mimeType: "video/mp4",
      uploadedAt: DateTime.parse("2025-10-01T02:20:00"),
      updatedAt: DateTime.parse("2025-10-02T04:55:45"),
    ),
    StoredFile(
      id: "10004",
      owner: 3,
      file: "/uploads/sheets/analytics.xlsx",
      name: "Instagram_Analytics.xlsx",
      size: 980_000,
      mimeType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      uploadedAt: DateTime.parse("2025-12-10T14:05:05"),
      updatedAt: DateTime.parse("2025-12-11T08:30:00"),
    ),
    StoredFile(
      id: "10005",
      owner: null,
      file: "/uploads/archives/dataset.gz",
      name: "Training_Dataset.gz",
      size: 540_500_000,
      mimeType: "application/gzip",
      uploadedAt: DateTime.parse("2025-09-15T11:11:11"),
      updatedAt: DateTime.parse("2025-09-15T11:11:11"),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ItemBuilderBlocCard(
        blocKey: 'fileHistory',
        paginated: true,
        customHeight: 90,
        dataSource: Memory.getFiles,
        dataSourceArgs: {},
        onDataEmpty: "No previous files found",
        onError: "Error fetching files",
        placeHolderItems: mockStoredFiles,
        item: (data) {
          return FileCard(
            file: data,
            size: FileCardSize.medium,
            showThumbnail: true,
          );
        },
      ),
    );
  }
}
