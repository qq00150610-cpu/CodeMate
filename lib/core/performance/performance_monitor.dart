// lib/core/performance/performance_monitor.dart
// 性能监控服务

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// 性能指标
class PerformanceMetrics {
  final double cpuUsage;
  final double memoryUsage;
  final double memoryTotal;
  final double memoryUsed;
  final double memoryAvailable;
  final int? appMemoryUsage;
  final DateTime timestamp;

  PerformanceMetrics({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.memoryTotal,
    required this.memoryUsed,
    required this.memoryAvailable,
    this.appMemoryUsage,
    required this.timestamp,
  });

  bool get isLowMemoryDevice => memoryTotal < 4 * 1024 * 1024 * 1024; // < 4GB

  bool get isHighMemoryUsage => memoryUsage > 85;

  Map<String, dynamic> toJson() => {
        'cpuUsage': cpuUsage,
        'memoryUsage': memoryUsage,
        'memoryTotal': memoryTotal,
        'memoryUsed': memoryUsed,
        'memoryAvailable': memoryAvailable,
        'appMemoryUsage': appMemoryUsage,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// 性能模式
enum PerformanceMode {
  normal,
  lowMemory,
  batterySaver,
}

/// 性能服务
class PerformanceService with ChangeNotifier {
  static final _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  Timer? _monitorTimer;
  PerformanceMetrics? _currentMetrics;
  PerformanceMode _currentMode = PerformanceMode.normal;

  // 设置
  int _memoryWarningThreshold = 85;
  int _checkIntervalSeconds = 5;

  // 降级配置
  bool _reduceEditorQuality = false;
  bool _disableAnimations = false;
  bool _limitHistoryItems = false;
  int _maxHistoryItems = 50;
  int _editorFontSize = 14;

  // Getters
  PerformanceMetrics? get currentMetrics => _currentMetrics;
  PerformanceMode get currentMode => _currentMode;
  bool get reduceEditorQuality => _reduceEditorQuality;
  bool get disableAnimations => _disableAnimations;
  bool get limitHistoryItems => _limitHistoryItems;
  int get maxHistoryItems => _maxHistoryItems;
  int get editorFontSize => _editorFontSize;

  /// 初始化
  Future<void> initialize() async {
    await _detectDeviceCapabilities();
    await _updateMetrics();
    _startMonitoring();
  }

  /// 检测设备能力
  Future<void> _detectDeviceCapabilities() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final totalMemory = androidInfo.totalMemory;
        
        // 根据内存设置初始模式
        if (totalMemory < 4 * 1024 * 1024 * 1024) {
          _enableLowMemoryMode();
        }
      }
    } catch (e) {
      debugPrint('Failed to detect device capabilities: $e');
    }
  }

  /// 开始监控
  void _startMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(
      Duration(seconds: _checkIntervalSeconds),
      (_) => _checkPerformance(),
    );
  }

  /// 检查性能
  Future<void> _checkPerformance() async {
    await _updateMetrics();
    
    if (_currentMetrics != null) {
      // 检查内存使用
      if (_currentMetrics!.isHighMemoryUsage) {
        await _handleHighMemoryUsage();
      }
    }
  }

  /// 更新指标
  Future<void> _updateMetrics() async {
    try {
      final metrics = await _getAndroidMemoryInfo();
      _currentMetrics = metrics;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update metrics: $e');
    }
  }

  /// 获取 Android 内存信息
  Future<PerformanceMetrics> _getAndroidMemoryInfo() async {
    // 使用 MethodChannel 获取原生内存信息
    // 这里简化实现，实际应通过 platform channel 获取
    final totalMemory = 8 * 1024 * 1024 * 1024.0; // 假设 8GB
    final freeMemory = 2 * 1024 * 1024 * 1024.0; // 假设 2GB 可用
    final usedMemory = totalMemory - freeMemory;
    final memoryUsagePercent = (usedMemory / totalMemory) * 100;

    return PerformanceMetrics(
      cpuUsage: 0, // 简化
      memoryUsage: memoryUsagePercent,
      memoryTotal: totalMemory,
      memoryUsed: usedMemory,
      memoryAvailable: freeMemory,
      timestamp: DateTime.now(),
    );
  }

  /// 处理高内存使用
  Future<void> _handleHighMemoryUsage() async {
    if (_currentMode == PerformanceMode.lowMemory) return;

    // 第一次警告
    if (_currentMetrics!.memoryUsage > 85) {
      await _cleanupCaches();
    }

    // 严重情况
    if (_currentMetrics!.memoryUsage > 90) {
      _enableLowMemoryMode();
    }
  }

  /// 清理缓存
  Future<void> _cleanupCaches() async {
    debugPrint('Cleaning up caches...');
    // 清理 WebView 缓存
    // 清理临时文件
  }

  /// 启用低内存模式
  void _enableLowMemoryMode() {
    _currentMode = PerformanceMode.lowMemory;
    _reduceEditorQuality = true;
    _disableAnimations = true;
    _limitHistoryItems = true;
    _maxHistoryItems = 20;
    _editorFontSize = 12;
    
    debugPrint('Low memory mode enabled');
    notifyListeners();
  }

  /// 禁用低内存模式
  void _disableLowMemoryMode() {
    _currentMode = PerformanceMode.normal;
    _reduceEditorQuality = false;
    _disableAnimations = false;
    _limitHistoryItems = false;
    _maxHistoryItems = 100;
    _editorFontSize = 14;
    
    debugPrint('Low memory mode disabled');
    notifyListeners();
  }

  /// 设置性能模式
  void setPerformanceMode(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.normal:
        _disableLowMemoryMode();
        break;
      case PerformanceMode.lowMemory:
        _enableLowMemoryMode();
        break;
      case PerformanceMode.batterySaver:
        _currentMode = PerformanceMode.batterySaver;
        _disableAnimations = true;
        _checkIntervalSeconds = 10;
        _startMonitoring();
        break;
    }
  }

  /// 设置检查间隔
  void setCheckInterval(int seconds) {
    _checkIntervalSeconds = seconds;
    _startMonitoring();
  }

  /// 获取推荐设置
  Map<String, dynamic> getRecommendedSettings() {
    final isLowEnd = _currentMetrics?.isLowMemoryDevice ?? false;

    return {
      'editorFontSize': isLowEnd ? 12 : 14,
      'enableAnimations': !isLowEnd,
      'maxHistoryItems': isLowEnd ? 20 : 100,
      'reduceEditorQuality': isLowEnd,
      'enableAutoComplete': !isLowEnd,
      'syntaxHighlightingDelay': isLowEnd ? 500 : 100,
    };
  }

  /// 生成性能报告
  String generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Performance Report ===');
    buffer.writeln('Mode: ${_currentMode.name}');
    buffer.writeln('Time: ${DateTime.now()}');
    
    if (_currentMetrics != null) {
      buffer.writeln('CPU Usage: ${_currentMetrics!.cpuUsage.toStringAsFixed(1)}%');
      buffer.writeln('Memory Usage: ${_currentMetrics!.memoryUsage.toStringAsFixed(1)}%');
      buffer.writeln('Memory Total: ${(_currentMetrics!.memoryTotal / 1024 / 1024 / 1024).toStringAsFixed(1)} GB');
      buffer.writeln('Memory Used: ${(_currentMetrics!.memoryUsed / 1024 / 1024 / 1024).toStringAsFixed(1)} GB');
      buffer.writeln('Memory Available: ${(_currentMetrics!.memoryAvailable / 1024 / 1024 / 1024).toStringAsFixed(1)} GB');
    }
    
    buffer.writeln('=== Current Settings ===');
    buffer.writeln('Reduce Editor Quality: $_reduceEditorQuality');
    buffer.writeln('Disable Animations: $_disableAnimations');
    buffer.writeln('Limit History Items: $_limitHistoryItems');
    buffer.writeln('Max History Items: $_maxHistoryItems');
    buffer.writeln('Editor Font Size: $_editorFontSize');
    
    return buffer.toString();
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }
}
