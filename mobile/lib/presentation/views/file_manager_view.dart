import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:matrix/matrix.dart';
import '../widgets/skeleton_loader.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../../core/app_provider.dart';
import '../widgets/image_viewer.dart';

class FileManagerView extends StatefulWidget {
  final AppProvider provider;
  final int initialTab;
  const FileManagerView({
    super.key,
    required this.provider,
    this.initialTab = 0,
  });

  @override
  State<FileManagerView> createState() => _FileManagerViewState();
}

class _FileManagerViewState extends State<FileManagerView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<_FileInfo> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final client = widget.provider.matrix.client;
    if (client == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final files = <_FileInfo>[];
      for (final room in client.rooms) {
        final timeline = await room.getTimeline();
        for (final event in timeline.events) {
          if (event.type == EventTypes.Message) {
            final content = event.content as Map<String, dynamic>?;
            final msgType = content?['msgtype'] as String?;
            if (msgType == 'm.image' ||
                msgType == 'm.video' ||
                msgType == 'm.file') {
              final mxcUrl = content?['url'] as String?;
              if (mxcUrl != null) {
                final info = content?['info'] as Map<String, dynamic>?;
                final thumbnailUrl = info?['thumbnail_url'] as String?;
                files.add(
                  _FileInfo(
                    name: event.body,
                    senderId: event.senderId,
                    roomId: room.id,
                    roomName: room.getLocalizedDisplayname(),
                    timestamp: event.originServerTs,
                    type: msgType == 'm.image'
                        ? FileType.image
                        : msgType == 'm.video'
                        ? FileType.video
                        : FileType.file,
                    mxcUrl: mxcUrl,
                    thumbnailMxcUrl: thumbnailUrl,
                    size: info?['size'] as int?,
                    mimeType: info?['mimetype'] as String?,
                  ),
                );
              }
            }
          }
        }
      }
      files.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (mounted)
        setState(() {
          _files = files;
          _loading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_FileInfo> _filterByType(FileType type) {
    if (type == FileType.image)
      return _files.where((f) => f.type == FileType.image).toList();
    if (type == FileType.video)
      return _files.where((f) => f.type == FileType.video).toList();
    return _files.where((f) => f.type == FileType.file).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = localeProvider.t;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          tooltip: localeProvider.t('back'),
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.sec(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('file_manager'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.acc(context),
          labelColor: AppColors.acc(context),
          unselectedLabelColor: AppColors.textHint(context),
          tabs: [
            Tab(text: t('images')),
            Tab(text: t('videos')),
            Tab(text: t('files')),
          ],
        ),
      ),
      body: _loading
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: List.generate(8, (_) => const CardSkeleton()),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGrid(_filterByType(FileType.image)),
                _buildGrid(_filterByType(FileType.video)),
                _buildList(_filterByType(FileType.file)),
              ],
            ),
    );
  }

  Widget _buildGrid(List<_FileInfo> files) {
    if (files.isEmpty) return _buildEmpty();
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: files.length,
      itemBuilder: (_, i) {
        final file = files[i];
        final client = widget.provider.matrix.client;
        final thumbnailUrl = file.thumbnailMxcUrl != null && client != null
            ? Uri.parse(
                file.thumbnailMxcUrl!,
              ).getThumbnailUri(client, width: 200, height: 200).toString()
            : null;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (file.type == FileType.image && client != null) {
              final httpUrl = Uri.parse(
                file.mxcUrl,
              ).getThumbnailUri(client, width: 2000, height: 2000).toString();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ImageViewer(imageUrl: httpUrl, title: file.name),
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.sf(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _buildFilePlaceholder(file),
                    )
                  : _buildFilePlaceholder(file),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilePlaceholder(_FileInfo file) {
    return Container(
      color: AppColors.sfAlt(context),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              file.type == FileType.image
                  ? LucideIcons.image
                  : LucideIcons.video,
              size: 28,
              color: AppColors.iconGray(context),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                file.name,
                style: TextStyle(
                  color: AppColors.textTertiary(context),
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<_FileInfo> files) {
    if (files.isEmpty) return _buildEmpty();
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: files.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final file = files[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.sf(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.sfAlt(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LucideIcons.file,
                  size: 20,
                  color: AppColors.iconGray(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${file.roomName} · ${_formatTime(file.timestamp)}',
                      style: TextStyle(
                        color: AppColors.textTertiary(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (file.size != null)
                Text(
                  _formatSize(file.size!),
                  style: TextStyle(
                    color: AppColors.iconGray(context),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.folderOpen,
            size: 48,
            color: AppColors.iconGray(context),
          ),
          const SizedBox(height: 12),
          Text(
            localeProvider.t('no_files'),
            style: TextStyle(color: AppColors.iconGray(context), fontSize: 15),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes ${localeProvider.t('unit_b')}';
    if (bytes < 1024 * 1024)
      return '${(bytes / 1024).toStringAsFixed(1)} ${localeProvider.t('unit_kb')}';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ${localeProvider.t('unit_mb')}';
  }
}

enum FileType { image, video, file }

class _FileInfo {
  final String name;
  final String senderId;
  final String roomId;
  final String roomName;
  final DateTime timestamp;
  final FileType type;
  final String mxcUrl;
  final String? thumbnailMxcUrl;
  final int? size;
  final String? mimeType;
  const _FileInfo({
    required this.name,
    required this.senderId,
    required this.roomId,
    required this.roomName,
    required this.timestamp,
    required this.type,
    required this.mxcUrl,
    this.thumbnailMxcUrl,
    this.size,
    this.mimeType,
  });
}
