// lib/features/update/services/update_service.dart
// 版本更新服务

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart.dart';
import 'package:permission_handler/permission_handler.dart';

/// 更新状态
enum UpdateStatus {
  idle,
  checking,
  available,
  downloading,
  downloaded,
  installing,
  error,
}

/// 更新信息
class UpdateInfo {
  final String version;
  final String releaseNotes;
  final String downloadUrl;
  final int fileSize;
  final DateTime releaseDate;
  final bool isPrerelease;
  final String? minApiLevel;

  UpdateInfo({
    required this.version,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.fileSize,
    required this.releaseDate,
    this.isPrerelease = false,
    this.minApiLevel,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) => UpdateInfo(
        version: json['tag_name']?.toString().replaceFirst('v', '') ?? '',
        releaseNotes: json['body'] ?? '',
        downloadUrl: json['assets']?[0]?['browser_download_url'] ?? '',
        fileSize: json['assets']?[0]?['size'] ?? 0,
        releaseDate: DateTime.tryParse(json['published_at'] ?? '') ?? DateTime.now(),
        isPrerelease: json['prerelease'] ?? false,
        minApiLevel: json['min_api_level']?.toString(),
      );

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  bool isNewerThan(String currentVersion) {
    return _compareVersions(version, currentVersion) > 0;
  }

  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    for (var i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 != p2) return p1.compareTo(p2);
    }
    return 0;
  }
}

/// 下载进度
class DownloadProgress {
  final int taskId;
  final double progress;
  final DownloadTaskStatus status;
  final String? error;

  DownloadProgress({
    required this.taskId,
    required this.progress,
    required this.status,
    this.error,
  });
}

/// 更新服务
class UpdateService with ChangeNotifier {
  static const _repositoryOwner = 'vhqtvn';
  static const _repositoryName = 'VHEditor-Android';
  static const _releasesUrl = 'https://api.github.com/repos/$_repositoryOwner/$_repositoryName/releases';
  static const _currentVersion = '2.22.0';

  // 单例
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  UpdateStatus _status = UpdateStatus.idle;
  UpdateInfo? _latestUpdate;
  double _downloadProgress = 0;
  String? _downloadPath;
  String? _errorMessage;
  Timer? _periodicCheckTimer;

  // 设置
  bool _autoCheckEnabled = true;
  bool _wifiOnlyDownload = true;
  bool _useBetaChannel = false;

  // Getters
  UpdateStatus get status => _status;
  UpdateInfo? get latestUpdate => _latestUpdate;
  double get downloadProgress => _downloadProgress;
  String? get downloadPath => _downloadPath;
  String? get errorMessage => _errorMessage;
  bool get autoCheckEnabled => _autoCheckEnabled;
  bool get wifiOnlyDownload => _wifiOnlyDownload;
  bool get useBetaChannel => _useBetaChannel;
  String get currentVersion => _currentVersion;

  bool get hasUpdate =>
      _latestUpdate != null && _latestUpdate!.isNewerThan(_currentVersion);

  /// 初始化
  Future<void> initialize() async {
    await FlutterDownloader.initialize();
    
    // 设置下载回调
    FlutterDownloader.registerCallback(_downloadCallback);
    
    // 启动定时检查（每24小时）
    if (_autoCheckEnabled) {
      _startPeriodicCheck();
    }
  }

  /// 启动定时检查
  void _startPeriodicCheck() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(
      const Duration(hours: 24),
      (_) => checkForUpdate(silent: true),
    );
  }

  /// 检查更新
  Future<UpdateInfo?> checkForUpdate({bool silent = false}) async {
    if (!silent) {
      _status = UpdateStatus.checking;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final updates = await _fetchReleases();
      
      if (updates.isEmpty) {
        if (!silent) {
          _status = UpdateStatus.idle;
          _errorMessage = '未找到可用更新';
        }
        notifyListeners();
        return null;
      }

      // 过滤测试版
      final stableUpdates = updates.where((u) => !u.isPrerelease).toList();
      final availableUpdates = _useBetaChannel ? updates : stableUpdates;

      if (availableUpdates.isEmpty) {
        _latestUpdate = updates.first;
      } else {
        _latestUpdate = availableUpdates.first;
      }

      if (!silent) {
        _status = hasUpdate ? UpdateStatus.available : UpdateStatus.idle;
      }
      
      notifyListeners();
      return _latestUpdate;
    } catch (e) {
      if (!silent) {
        _status = UpdateStatus.error;
        _errorMessage = '检查更新失败: $e';
      }
      notifyListeners();
      return null;
    }
  }

  /// 获取 releases 列表
  Future<List<UpdateInfo>> _fetchReleases() async {
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse(_releasesUrl),
    );
    
    request.headers.set('Accept', 'application/vnd.github+json');
    request.headers.set('User-Agent', 'CodeMate-Android');
    
    // 如果配置了 token，可以添加认证
    // request.headers.set('Authorization', 'Bearer $token');

    final response = await request.close().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException('请求超时'),
    );

    final body = await response.transform(utf8.decoder).join();
    
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch releases: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(body);
    return data.map((r) => UpdateInfo.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// 下载更新
  Future<void> downloadUpdate() async {
    if (_latestUpdate == null || _latestUpdate!.downloadUrl.isEmpty) {
      _errorMessage = '无下载链接';
      notifyListeners();
      return;
    }

    // 检查权限
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      _errorMessage = '需要存储权限才能下载更新';
      notifyListeners();
      return;
    }

    // 检查 WiFi
    if (_wifiOnlyDownload) {
      final isWifi = await _checkWifiConnection();
      if (!isWifi) {
        _errorMessage = '当前不在 WiFi 环境';
        notifyListeners();
        return;
      }
    }

    _status = UpdateStatus.downloading;
    _downloadProgress = 0;
    _errorMessage = null;
    notifyListeners();

    try {
      // 获取下载目录
      final dir = await getExternalStorageDirectory();
      final savePath = '${dir?.path}/CodeMate_${_latestUpdate!.version}.apk';

      // 下载文件
      final taskId = await FlutterDownloader.enqueue(
        url: _latestUpdate!.downloadUrl,
        savedDir: dir?.path ?? '',
        fileName: 'CodeMate_${_latestUpdate!.version}.apk',
        showNotification: true,
        openFileFromNotification: false,
        saveInPublicStorage: true,
      );

      if (taskId != null) {
        _downloadPath = savePath;
        _downloadProgress = 0;
      } else {
        throw Exception('Failed to start download');
      }
    } catch (e) {
      _status = UpdateStatus.error;
      _errorMessage = '下载失败: $e';
      notifyListeners();
    }
  }

  /// 静态下载回调
  static void _downloadCallback(String id, DownloadTaskStatus status, int progress) {
    // 通知更新服务
    instance._handleDownloadProgress(id, status, progress);
  }

  void _handleDownloadProgress(String taskId, DownloadTaskStatus status, int progress) {
    _downloadProgress = progress / 100.0;

    if (status == DownloadTaskStatus.complete) {
      _status = UpdateStatus.downloaded;
      _downloadPath = _latestUpdate?.downloadUrl;
    } else if (status == DownloadTaskStatus.failed) {
      _status = UpdateStatus.error;
      _errorMessage = '下载失败，请重试';
    }

    notifyListeners();
  }

  /// 安装更新
  Future<void> installUpdate() async {
    if (_downloadPath == null) {
      _errorMessage = 'APK 文件不存在';
      notifyListeners();
      return;
    }

    _status = UpdateStatus.installing;
    notifyListeners();

    try {
      // 使用 intent 安装
      final result = await Process.run(
        'am',
        ['start', '-a', 'android.intent.action.VIEW',
         '-n', 'com.android.packageinstaller/.PackageInstallerActivity',
         '-d', _downloadPath!],
      );

      if (result.exitCode != 0) {
        throw Exception('Failed to open installer');
      }
    } catch (e) {
      _errorMessage = '安装失败: $e';
      _status = UpdateStatus.error;
      notifyListeners();
    }
  }

  /// 请求存储权限
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();
      
      if (androidInfo >= 33) {
        // Android 13+ 需要 READ_MEDIA_IMAGES 权限
        final status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true;
  }

  /// 获取 Android 版本
  Future<int> _getAndroidVersion() async {
    // 简单实现，实际应该使用 device_info_plus
    return 33;
  }

  /// 检查 WiFi 连接
  Future<bool> _checkWifiConnection() async {
    // 简单实现，实际应该使用 connectivity_plus
    return true;
  }

  /// 更新设置
  void updateSettings({
    bool? autoCheck,
    bool? wifiOnly,
    bool? beta,
  }) {
    if (autoCheck != null) _autoCheckEnabled = autoCheck;
    if (wifiOnly != null) _wifiOnlyDownload = wifiOnly;
    if (beta != null) _useBetaChannel = beta;

    if (_autoCheckEnabled) {
      _startPeriodicCheck();
    } else {
      _periodicCheckTimer?.cancel();
    }

    notifyListeners();
  }

  /// 重置状态
  void reset() {
    _status = UpdateStatus.idle;
    _downloadProgress = 0;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _periodicCheckTimer?.cancel();
    super.dispose();
  }
}
