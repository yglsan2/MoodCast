import 'dart:convert';

/// Lien avec la personne à alerter (style cercle Life360).
enum SafetyRelation {
  parent,
  family,
  friend,
  other;

  String get labelFr {
    switch (this) {
      case SafetyRelation.parent:
        return 'Parent';
      case SafetyRelation.family:
        return 'Famille';
      case SafetyRelation.friend:
        return 'Ami(e)';
      case SafetyRelation.other:
        return 'Autre proche';
    }
  }

  String get emoji {
    switch (this) {
      case SafetyRelation.parent:
        return '👨‍👩‍👧';
      case SafetyRelation.family:
        return '🏠';
      case SafetyRelation.friend:
        return '🤝';
      case SafetyRelation.other:
        return '💛';
    }
  }

  static SafetyRelation fromStorage(String? raw) {
    switch (raw) {
      case 'parent':
        return SafetyRelation.parent;
      case 'family':
        return SafetyRelation.family;
      case 'friend':
        return SafetyRelation.friend;
      default:
        return SafetyRelation.other;
    }
  }
}

/// Contact de confiance du cercle MoodSafe / Mode Diwall.
class SafetyContact {
  const SafetyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relation = SafetyRelation.other,
    this.priority = false,
  });

  final String id;
  final String name;
  final String phone;
  final SafetyRelation relation;

  /// Contact d’urgence prioritaire : alerté en premier.
  final bool priority;

  String get cleanPhone => phone.replaceAll(RegExp(r'[\s\.\-\(\)]'), '');

  SafetyContact copyWith({
    String? name,
    String? phone,
    SafetyRelation? relation,
    bool? priority,
  }) =>
      SafetyContact(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        relation: relation ?? this.relation,
        priority: priority ?? this.priority,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'relation': relation.name,
        'priority': priority,
      };

  factory SafetyContact.fromJson(Map<String, dynamic> json) => SafetyContact(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        relation: SafetyRelation.fromStorage(json['relation'] as String?),
        priority: json['priority'] as bool? ?? false,
      );
}

/// Groupe nommé (amis, famille, coloc…) dans le cercle de confiance.
class SafetyGroup {
  const SafetyGroup({
    required this.id,
    required this.name,
    required this.contactIds,
  });

  final String id;
  final String name;
  final List<String> contactIds;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'contactIds': contactIds,
      };

  factory SafetyGroup.fromJson(Map<String, dynamic> json) => SafetyGroup(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        contactIds: (json['contactIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  SafetyGroup copyWith({String? name, List<String>? contactIds}) => SafetyGroup(
        id: id,
        name: name ?? this.name,
        contactIds: contactIds ?? this.contactIds,
      );
}

/// Profil de la personne protégée (ex. enfant qui a le téléphone).
class ProtectedProfile {
  const ProtectedProfile({
    this.displayName = '',
    this.childFriendlyMode = false,
    this.setupCompleted = false,
  });

  final String displayName;
  final bool childFriendlyMode;
  final bool setupCompleted;

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'childFriendlyMode': childFriendlyMode,
        'setupCompleted': setupCompleted,
      };

  factory ProtectedProfile.fromJson(Map<String, dynamic> json) => ProtectedProfile(
        displayName: json['displayName'] as String? ?? '',
        childFriendlyMode: json['childFriendlyMode'] as bool? ?? false,
        setupCompleted: json['setupCompleted'] as bool? ?? false,
      );

  ProtectedProfile copyWith({
    String? displayName,
    bool? childFriendlyMode,
    bool? setupCompleted,
  }) =>
      ProtectedProfile(
        displayName: displayName ?? this.displayName,
        childFriendlyMode: childFriendlyMode ?? this.childFriendlyMode,
        setupCompleted: setupCompleted ?? this.setupCompleted,
      );
}

class SafetyCircleData {
  const SafetyCircleData({
    this.contacts = const [],
    this.groups = const [],
    this.profile = const ProtectedProfile(),
  });

  final List<SafetyContact> contacts;
  final List<SafetyGroup> groups;
  final ProtectedProfile profile;

  Map<String, dynamic> toJson() => {
        'contacts': contacts.map((c) => c.toJson()).toList(),
        'groups': groups.map((g) => g.toJson()).toList(),
        'profile': profile.toJson(),
      };

  factory SafetyCircleData.fromJson(Map<String, dynamic> json) => SafetyCircleData(
        contacts: (json['contacts'] as List<dynamic>?)
                ?.map((e) => SafetyContact.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        groups: (json['groups'] as List<dynamic>?)
                ?.map((e) => SafetyGroup.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        profile: json['profile'] is Map
            ? ProtectedProfile.fromJson(Map<String, dynamic>.from(json['profile'] as Map))
            : const ProtectedProfile(),
      );

  static SafetyCircleData? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return SafetyCircleData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  String encode() => jsonEncode(toJson());

  SafetyCircleData copyWith({
    List<SafetyContact>? contacts,
    List<SafetyGroup>? groups,
    ProtectedProfile? profile,
  }) =>
      SafetyCircleData(
        contacts: contacts ?? this.contacts,
        groups: groups ?? this.groups,
        profile: profile ?? this.profile,
      );

  List<SafetyContact> get priorityContacts =>
      contacts.where((c) => c.priority && c.cleanPhone.isNotEmpty).toList();

  List<SafetyContact> get secondaryContacts =>
      contacts.where((c) => !c.priority && c.cleanPhone.isNotEmpty).toList();

  /// Destinataires triés : priorité d’abord, puis les autres (dédupliqués).
  List<SafetyContact> resolveAlertRecipients({Set<String>? onlyGroupIds}) {
    Iterable<SafetyContact> source;
    if (onlyGroupIds != null && onlyGroupIds.isNotEmpty) {
      final ids = <String>{};
      for (final g in groups) {
        if (onlyGroupIds.contains(g.id)) ids.addAll(g.contactIds);
      }
      final byId = {for (final c in contacts) c.id: c};
      source = ids.map((id) => byId[id]).whereType<SafetyContact>();
    } else {
      source = contacts;
    }

    final seen = <String>{};
    final priority = <SafetyContact>[];
    final rest = <SafetyContact>[];
    for (final c in source) {
      final p = c.cleanPhone;
      if (p.isEmpty || seen.contains(p)) continue;
      seen.add(p);
      if (c.priority) {
        priority.add(c);
      } else {
        rest.add(c);
      }
    }
    return [...priority, ...rest];
  }

  /// Groupes automatiques par relation (pour l’UI type Life360).
  Map<SafetyRelation, List<SafetyContact>> contactsByRelation() {
    final map = {for (final r in SafetyRelation.values) r: <SafetyContact>[]};
    for (final c in contacts) {
      map[c.relation]!.add(c);
    }
    return map;
  }
}

/// Entrée du journal d'alertes Mode Diwall (local).
class AttentionAlertLog {
  const AttentionAlertLog({
    required this.at,
    required this.recipientCount,
    required this.messagePreview,
    required this.sentDirect,
  });

  final DateTime at;
  final int recipientCount;
  final String messagePreview;
  final int sentDirect;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'recipientCount': recipientCount,
        'messagePreview': messagePreview,
        'sentDirect': sentDirect,
      };

  factory AttentionAlertLog.fromJson(Map<String, dynamic> json) => AttentionAlertLog(
        at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
        recipientCount: json['recipientCount'] as int? ?? 0,
        messagePreview: json['messagePreview'] as String? ?? '',
        sentDirect: json['sentDirect'] as int? ?? 0,
      );
}
