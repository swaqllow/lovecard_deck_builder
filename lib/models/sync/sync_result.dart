// lib/models/sync/sync_result.dart
import '../card/base_card.dart';

/// 同期結果を表現するクラス
/// 
/// カードデータの同期処理の結果を包括的に管理します
class SyncResult {
  // ========== 基本情報 ==========
  
  /// 同期が成功したかどうか
  final bool success;
  
  /// ユーザー向けメッセージ
  final String message;
  
  /// 開発者向け詳細メッセージ
  final String? debugMessage;
  
  /// 同期処理の開始時刻
  final DateTime startTime;
  
  /// 同期処理の終了時刻
  final DateTime endTime;
  
  // ========== バージョン管理 ==========
  
  /// 同期前のデータバージョン
  final String? fromVersion;
  
  /// 同期後のデータバージョン
  final String? toVersion;
  
  /// 次回同期推奨時刻
  final DateTime? nextSyncRecommendedAt;
  
  // ========== 更新統計 ==========
  
  /// 新規追加されたカード数
  final int addedCardsCount;
  
  /// 更新されたカード数
  final int updatedCardsCount;
  
  /// 削除されたカード数
  final int deletedCardsCount;
  
  /// 総処理カード数
  int get totalProcessedCards => addedCardsCount + updatedCardsCount + deletedCardsCount;
  
  /// 実際に変更があったかどうか
  bool get hasChanges => totalProcessedCards > 0;
  
  // ========== 詳細データ ==========
  
  /// 新規追加されたカードの詳細
  final List<BaseCard>? addedCards;
  
  /// 更新されたカードの詳細
  final List<BaseCard>? updatedCards;
  
  /// 削除されたカードのID一覧
  final List<String>? deletedCardIds;
  
  /// 更新に失敗したカードのリスト
  final List<SyncFailure>? failures;
  
  // ========== パフォーマンス情報 ==========
  
  /// 同期にかかった時間（ミリ秒）
  int get durationMs => endTime.difference(startTime).inMilliseconds;
  
  /// データ転送量（バイト）推定
  final int? transferredBytes;
  
  /// ネットワーク状況
  final NetworkStatus? networkStatus;
  
  // ========== エラー情報 ==========
  
  /// エラーの種類
  final SyncErrorType? errorType;
  
  /// エラーコード
  final String? errorCode;
  
  /// 元のエラー情報
  final dynamic originalError;
  
  /// リトライ可能かどうか
  final bool canRetry;
  
  /// 推奨リトライ間隔（秒）
  final int? retryAfterSeconds;
  
  // ========== ユーザー体験 ==========
  
  /// 重要度レベル
  final SyncImportanceLevel importanceLevel;
  
  /// ユーザーに推奨するアクション
  final List<UserAction>? recommendedActions;
  
  /// 通知すべきかどうか
  final bool shouldNotifyUser;

  const SyncResult({
    required this.success,
    required this.message,
    required this.startTime,
    required this.endTime,
    this.debugMessage,
    this.fromVersion,
    this.toVersion,
    this.nextSyncRecommendedAt,
    this.addedCardsCount = 0,
    this.updatedCardsCount = 0,
    this.deletedCardsCount = 0,
    this.addedCards,
    this.updatedCards,
    this.deletedCardIds,
    this.failures,
    this.transferredBytes,
    this.networkStatus,
    this.errorType,
    this.errorCode,
    this.originalError,
    this.canRetry = false,
    this.retryAfterSeconds,
    this.importanceLevel = SyncImportanceLevel.normal,
    this.recommendedActions,
    this.shouldNotifyUser = false,
  });

  // ========== ファクトリーメソッド ==========

  /// 成功時のSyncResultを生成
  factory SyncResult.success({
    required String message,
    String? fromVersion,
    String? toVersion,
    int addedCardsCount = 0,
    int updatedCardsCount = 0,
    int deletedCardsCount = 0,
    List<BaseCard>? addedCards,
    List<BaseCard>? updatedCards,
    List<String>? deletedCardIds,
    int? transferredBytes,
    NetworkStatus? networkStatus,
    DateTime? nextSyncAt,
    SyncImportanceLevel importance = SyncImportanceLevel.normal,
    bool shouldNotify = false,
  }) {
    final now = DateTime.now();
    return SyncResult(
      success: true,
      message: message,
      startTime: now.subtract(Duration(milliseconds: 100)), // 仮の開始時刻
      endTime: now,
      fromVersion: fromVersion,
      toVersion: toVersion,
      addedCardsCount: addedCardsCount,
      updatedCardsCount: updatedCardsCount,
      deletedCardsCount: deletedCardsCount,
      addedCards: addedCards,
      updatedCards: updatedCards,
      deletedCardIds: deletedCardIds,
      transferredBytes: transferredBytes,
      networkStatus: networkStatus,
      nextSyncRecommendedAt: nextSyncAt,
      importanceLevel: importance,
      shouldNotifyUser: shouldNotify,
    );
  }

  /// エラー時のSyncResultを生成
  factory SyncResult.error({
    required String message,
    String? debugMessage,
    SyncErrorType? errorType,
    String? errorCode,
    dynamic originalError,
    bool canRetry = true,
    int? retryAfterSeconds,
    List<UserAction>? recommendedActions,
    SyncImportanceLevel importance = SyncImportanceLevel.high,
  }) {
    final now = DateTime.now();
    return SyncResult(
      success: false,
      message: message,
      debugMessage: debugMessage,
      startTime: now.subtract(Duration(milliseconds: 50)),
      endTime: now,
      errorType: errorType,
      errorCode: errorCode,
      originalError: originalError,
      canRetry: canRetry,
      retryAfterSeconds: retryAfterSeconds,
      recommendedActions: recommendedActions,
      importanceLevel: importance,
      shouldNotifyUser: true,
    );
  }

  /// 更新なし（最新）時のSyncResultを生成
  factory SyncResult.noUpdate({
    String? currentVersion,
    DateTime? nextSyncAt,
    NetworkStatus? networkStatus,
  }) {
    final now = DateTime.now();
    return SyncResult(
      success: true,
      message: 'データは最新です',
      startTime: now.subtract(Duration(milliseconds: 10)),
      endTime: now,
      fromVersion: currentVersion,
      toVersion: currentVersion,
      networkStatus: networkStatus,
      nextSyncRecommendedAt: nextSyncAt,
      importanceLevel: SyncImportanceLevel.low,
    );
  }

  // ========== JSON変換 ==========

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      debugMessage: json['debug_message'],
      startTime: json['start_time'] != null 
          ? DateTime.parse(json['start_time']) 
          : DateTime.now(),
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time']) 
          : DateTime.now(),
      fromVersion: json['from_version'],
      toVersion: json['to_version'],
      nextSyncRecommendedAt: json['next_sync_at'] != null
          ? DateTime.parse(json['next_sync_at'])
          : null,
      addedCardsCount: json['added_cards_count'] ?? 0,
      updatedCardsCount: json['updated_cards_count'] ?? 0,
      deletedCardsCount: json['deleted_cards_count'] ?? 0,
      deletedCardIds: json['deleted_card_ids'] != null
          ? List<String>.from(json['deleted_card_ids'])
          : null,
      transferredBytes: json['transferred_bytes'],
      networkStatus: json['network_status'] != null
          ? NetworkStatus.fromString(json['network_status'])
          : null,
      errorType: json['error_type'] != null
          ? SyncErrorType.fromString(json['error_type'])
          : null,
      errorCode: json['error_code'],
      canRetry: json['can_retry'] ?? false,
      retryAfterSeconds: json['retry_after_seconds'],
      importanceLevel: json['importance_level'] != null
          ? SyncImportanceLevel.fromString(json['importance_level'])
          : SyncImportanceLevel.normal,
      shouldNotifyUser: json['should_notify_user'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'debug_message': debugMessage,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'from_version': fromVersion,
      'to_version': toVersion,
      'next_sync_at': nextSyncRecommendedAt?.toIso8601String(),
      'added_cards_count': addedCardsCount,
      'updated_cards_count': updatedCardsCount,
      'deleted_cards_count': deletedCardsCount,
      'total_processed_cards': totalProcessedCards,
      'has_changes': hasChanges,
      'deleted_card_ids': deletedCardIds,
      'duration_ms': durationMs,
      'transferred_bytes': transferredBytes,
      'network_status': networkStatus?.toString(),
      'error_type': errorType?.toString(),
      'error_code': errorCode,
      'can_retry': canRetry,
      'retry_after_seconds': retryAfterSeconds,
      'importance_level': importanceLevel.toString(),
      'should_notify_user': shouldNotifyUser,
    };
  }

  // ========== 便利なメソッド ==========

  /// パフォーマンス情報の文字列
  String get performanceInfo {
    final duration = (durationMs / 1000).toStringAsFixed(2);
    final throughput = transferredBytes != null 
        ? '${(transferredBytes! / 1024).toStringAsFixed(1)}KB'
        : '不明';
    
    return '処理時間: ${duration}秒, データ転送量: $throughput';
  }

  /// ユーザー向けの詳細メッセージ
  String get userDetailMessage {
    if (!success) return message;
    
    if (!hasChanges) return '$message (変更なし)';
    
    final parts = <String>[];
    if (addedCardsCount > 0) parts.add('新規${addedCardsCount}枚');
    if (updatedCardsCount > 0) parts.add('更新${updatedCardsCount}枚');
    if (deletedCardsCount > 0) parts.add('削除${deletedCardsCount}枚');
    
    return '$message (${parts.join(', ')})';
  }

  /// 開発者向けの詳細情報
  String get developerInfo {
    return '''
SyncResult:
  Success: $success
  Message: $message
  Debug: $debugMessage
  Version: $fromVersion → $toVersion
  Changes: Added($addedCardsCount) Updated($updatedCardsCount) Deleted($deletedCardsCount)
  Performance: ${performanceInfo}
  Network: $networkStatus
  Error: $errorType ($errorCode)
  Retry: $canRetry (after ${retryAfterSeconds}s)
''';
  }

  @override
  String toString() {
    return 'SyncResult(success: $success, message: $message, changes: $totalProcessedCards, duration: ${durationMs}ms)';
  }
}

// ========== 関連Enumクラス ==========

/// 同期エラーの種類
enum SyncErrorType {
  network,        // ネットワークエラー
  server,         // サーバーエラー
  authentication, // 認証エラー
  parsing,        // データ解析エラー
  storage,        // ローカルストレージエラー
  version,        // バージョン不整合
  timeout,        // タイムアウト
  unknown;        // 不明なエラー

  static SyncErrorType fromString(String value) {
    return SyncErrorType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncErrorType.unknown,
    );
  }
}

/// ネットワーク状況
enum NetworkStatus {
  excellent,  // 優秀
  good,       // 良好
  fair,       // 普通
  poor,       // 不良
  offline;    // オフライン

  static NetworkStatus fromString(String value) {
    return NetworkStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NetworkStatus.fair,
    );
  }

  String get displayName {
    switch (this) {
      case NetworkStatus.excellent: return '優秀';
      case NetworkStatus.good: return '良好';
      case NetworkStatus.fair: return '普通';
      case NetworkStatus.poor: return '不良';
      case NetworkStatus.offline: return 'オフライン';
    }
  }
}

/// 重要度レベル
enum SyncImportanceLevel {
  low,     // 低（ユーザーに通知不要）
  normal,  // 普通（必要に応じて通知）
  high,    // 高（積極的に通知）
  critical; // 緊急（必ず通知）

  static SyncImportanceLevel fromString(String value) {
    return SyncImportanceLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncImportanceLevel.normal,
    );
  }

  String get displayName {
    switch (this) {
      case SyncImportanceLevel.low: return '情報';
      case SyncImportanceLevel.normal: return '通常';
      case SyncImportanceLevel.high: return '重要';
      case SyncImportanceLevel.critical: return '緊急';
    }
  }
}

/// 同期失敗の詳細
class SyncFailure {
  final String cardId;
  final String cardName;
  final String error;
  final SyncErrorType errorType;
  final bool canRetry;

  const SyncFailure({
    required this.cardId,
    required this.cardName,
    required this.error,
    required this.errorType,
    this.canRetry = true,
  });

  factory SyncFailure.fromJson(Map<String, dynamic> json) {
    return SyncFailure(
      cardId: json['card_id'] ?? '',
      cardName: json['card_name'] ?? '',
      error: json['error'] ?? '',
      errorType: SyncErrorType.fromString(json['error_type'] ?? 'unknown'),
      canRetry: json['can_retry'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_id': cardId,
      'card_name': cardName,
      'error': error,
      'error_type': errorType.name,
      'can_retry': canRetry,
    };
  }
}

/// ユーザー推奨アクション
class UserAction {
  final String title;
  final String description;
  final UserActionType type;
  final Map<String, dynamic>? parameters;

  const UserAction({
    required this.title,
    required this.description,
    required this.type,
    this.parameters,
  });

  factory UserAction.fromJson(Map<String, dynamic> json) {
    return UserAction(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: UserActionType.fromString(json['type'] ?? 'info'),
      parameters: json['parameters'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'parameters': parameters,
    };
  }
}

/// ユーザーアクションの種類
enum UserActionType {
  info,           // 情報表示
  retry,          // リトライ
  checkNetwork,   // ネットワーク確認
  clearCache,     // キャッシュクリア
  contactSupport, // サポート連絡
  updateApp;      // アプリ更新

  static UserActionType fromString(String value) {
    return UserActionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserActionType.info,
    );
  }

  String get displayName {
    switch (this) {
      case UserActionType.info: return '詳細確認';
      case UserActionType.retry: return '再試行';
      case UserActionType.checkNetwork: return 'ネットワーク確認';
      case UserActionType.clearCache: return 'キャッシュクリア';
      case UserActionType.contactSupport: return 'サポート連絡';
      case UserActionType.updateApp: return 'アプリ更新';
    }
  }
}