import 'dart:convert';

/// Qui reçoit l’alerte MoodSafe (profil de diffusion).
class DiffusionProfile {
  const DiffusionProfile({
    this.notifyPriorityFirst = true,
    this.notifyFullCircle = true,
    this.notifySisterAid = true,
    this.defaultTrigger = AttentionTriggerStyle.deadManSwitch,
    this.attentionHoldSeconds = 3,
    this.classicCancelSeconds = 8,
  });

  /// Vagues : prioritaires ★ d’abord.
  final bool notifyPriorityFirst;

  /// Puis le reste du cercle (amis / famille non prioritaires).
  final bool notifyFullCircle;

  /// Lien Sœurs si opt-in + attestation femme.
  final bool notifySisterAid;

  /// Déclencheur par défaut sur l’écran Mode Diwall.
  final AttentionTriggerStyle defaultTrigger;

  /// Durée du maintien « tout va bien » (Mode Diwall), en secondes.
  final int attentionHoldSeconds;

  /// Délai d’annulation pour le SOS classique (secondes).
  final int classicCancelSeconds;

  Duration get attentionHoldDuration =>
      Duration(seconds: attentionHoldSeconds.clamp(2, 10));

  DiffusionProfile copyWith({
    bool? notifyPriorityFirst,
    bool? notifyFullCircle,
    bool? notifySisterAid,
    AttentionTriggerStyle? defaultTrigger,
    int? attentionHoldSeconds,
    int? classicCancelSeconds,
  }) =>
      DiffusionProfile(
        notifyPriorityFirst: notifyPriorityFirst ?? this.notifyPriorityFirst,
        notifyFullCircle: notifyFullCircle ?? this.notifyFullCircle,
        notifySisterAid: notifySisterAid ?? this.notifySisterAid,
        defaultTrigger: defaultTrigger ?? this.defaultTrigger,
        attentionHoldSeconds: attentionHoldSeconds ?? this.attentionHoldSeconds,
        classicCancelSeconds: classicCancelSeconds ?? this.classicCancelSeconds,
      );

  Map<String, dynamic> toJson() => {
        'notifyPriorityFirst': notifyPriorityFirst,
        'notifyFullCircle': notifyFullCircle,
        'notifySisterAid': notifySisterAid,
        'defaultTrigger': defaultTrigger.name,
        'attentionHoldSeconds': attentionHoldSeconds,
        'classicCancelSeconds': classicCancelSeconds,
      };

  factory DiffusionProfile.fromJson(Map<String, dynamic> json) => DiffusionProfile(
        notifyPriorityFirst: json['notifyPriorityFirst'] as bool? ?? true,
        notifyFullCircle: json['notifyFullCircle'] as bool? ?? true,
        notifySisterAid: json['notifySisterAid'] as bool? ?? true,
        defaultTrigger: AttentionTriggerStyle.fromStorage(json['defaultTrigger'] as String?),
        attentionHoldSeconds: (json['attentionHoldSeconds'] as int? ?? 3).clamp(2, 10),
        classicCancelSeconds: json['classicCancelSeconds'] as int? ?? 8,
      );

  String encode() => jsonEncode(toJson());

  static DiffusionProfile tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return const DiffusionProfile();
    try {
      return DiffusionProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const DiffusionProfile();
    }
  }
}

enum AttentionTriggerStyle {
  /// Mode Diwall : maintenir N s = OK ; relâcher tôt = alerte.
  deadManSwitch,

  /// Appui = compte à rebours ; annulation possible ; puis alerte.
  classicCancelWindow;

  static AttentionTriggerStyle fromStorage(String? raw) {
    if (raw == 'classicCancelWindow') return AttentionTriggerStyle.classicCancelWindow;
    return AttentionTriggerStyle.deadManSwitch;
  }

  String get labelFr => this == AttentionTriggerStyle.deadManSwitch
      ? 'Diwall (relâcher = alerte)'
      : 'SOS classique (délai d’annulation)';
}

/// Statut d’envoi côté expéditeur (accusé local).
enum DeliveryStatus { pending, sentDirect, composerOpened, failed, skipped }

class AlertDeliveryAck {
  const AlertDeliveryAck({
    required this.id,
    required this.label,
    required this.phone,
    required this.layer,
    required this.status,
  });

  final String id;
  final String label;
  final String phone;
  final AlertLayer layer;
  final DeliveryStatus status;

  String get statusLabelFr {
    switch (status) {
      case DeliveryStatus.pending:
        return 'En cours…';
      case DeliveryStatus.sentDirect:
        return 'SMS envoyé';
      case DeliveryStatus.composerOpened:
        return 'SMS à envoyer';
      case DeliveryStatus.failed:
        return 'Échec';
      case DeliveryStatus.skipped:
        return 'Ignoré (réglages)';
    }
  }

  AlertDeliveryAck copyWith({DeliveryStatus? status}) => AlertDeliveryAck(
        id: id,
        label: label,
        phone: phone,
        layer: layer,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'phone': phone,
        'layer': layer.name,
        'status': status.name,
      };

  factory AlertDeliveryAck.fromJson(Map<String, dynamic> json) => AlertDeliveryAck(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        layer: AlertLayer.fromStorage(json['layer'] as String?),
        status: DeliveryStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => DeliveryStatus.pending,
        ),
      );
}

enum AlertLayer {
  priority,
  circle,
  sisterAid;

  static AlertLayer fromStorage(String? raw) {
    switch (raw) {
      case 'circle':
        return AlertLayer.circle;
      case 'sisterAid':
        return AlertLayer.sisterAid;
      default:
        return AlertLayer.priority;
    }
  }

  String get labelFr {
    switch (this) {
      case AlertLayer.priority:
        return 'Prioritaire';
      case AlertLayer.circle:
        return 'Cercle';
      case AlertLayer.sisterAid:
        return 'Lien Sœurs';
    }
  }
}

/// États système MoodSafe unifiés.
enum MoodSafeSystemState {
  veille,
  attentionArmee,
  alerteActive,
  resolu;

  String get labelFr {
    switch (this) {
      case MoodSafeSystemState.veille:
        return 'Veille';
      case MoodSafeSystemState.attentionArmee:
        return 'Diwall armé';
      case MoodSafeSystemState.alerteActive:
        return 'Alerte active';
      case MoodSafeSystemState.resolu:
        return 'Résolu';
    }
  }
}

/// Session d’alerte en cours (persistée localement).
class MoodSafeAlertSession {
  const MoodSafeAlertSession({
    required this.id,
    required this.startedAt,
    required this.message,
    required this.deliveries,
    this.lastLat,
    this.lastLng,
    this.active = true,
    this.triggerStyle = AttentionTriggerStyle.deadManSwitch,
  });

  final String id;
  final DateTime startedAt;
  final String message;
  final List<AlertDeliveryAck> deliveries;
  final double? lastLat;
  final double? lastLng;
  final bool active;
  final AttentionTriggerStyle triggerStyle;

  int get sentCount =>
      deliveries.where((d) => d.status == DeliveryStatus.sentDirect).length;

  int get notifiedOrPreparedCount => deliveries
      .where(
        (d) =>
            d.status == DeliveryStatus.sentDirect ||
            d.status == DeliveryStatus.composerOpened,
      )
      .length;

  MoodSafeAlertSession copyWith({
    String? message,
    List<AlertDeliveryAck>? deliveries,
    double? lastLat,
    double? lastLng,
    bool? active,
  }) =>
      MoodSafeAlertSession(
        id: id,
        startedAt: startedAt,
        message: message ?? this.message,
        deliveries: deliveries ?? this.deliveries,
        lastLat: lastLat ?? this.lastLat,
        lastLng: lastLng ?? this.lastLng,
        active: active ?? this.active,
        triggerStyle: triggerStyle,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'message': message,
        'deliveries': deliveries.map((d) => d.toJson()).toList(),
        'lastLat': lastLat,
        'lastLng': lastLng,
        'active': active,
        'triggerStyle': triggerStyle.name,
      };

  factory MoodSafeAlertSession.fromJson(Map<String, dynamic> json) => MoodSafeAlertSession(
        id: json['id'] as String? ?? '',
        startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(),
        message: json['message'] as String? ?? '',
        deliveries: (json['deliveries'] as List<dynamic>?)
                ?.map((e) => AlertDeliveryAck.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        lastLat: (json['lastLat'] as num?)?.toDouble(),
        lastLng: (json['lastLng'] as num?)?.toDouble(),
        active: json['active'] as bool? ?? true,
        triggerStyle: AttentionTriggerStyle.fromStorage(json['triggerStyle'] as String?),
      );

  String encode() => jsonEncode(toJson());

  static MoodSafeAlertSession? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return MoodSafeAlertSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
