import 'dart:convert';

/// Profil local « Lien Sœurs » : entraide **réservée aux femmes** (opt-in strict).
class SisterAidProfile {
  const SisterAidProfile({
    this.enabled = false,
    this.availableToHelp = false,
    this.nickname = '',
    this.shareApproxLocation = true,
    this.alertSistersOnAttention = true,
    this.demoNearbyEnabled = true,
    this.radiusKm = 2.0,
    this.womenOnlyAttestation = false,
  });

  /// A accepté de participer au réseau d’entraide.
  final bool enabled;

  /// Visible comme « prête à aider » (quand un backend existera / pour le cercle lié).
  final bool availableToHelp;

  /// Pseudo affiché aux autres (pas le nom civil).
  final String nickname;

  final bool shareApproxLocation;

  /// Inclure le Lien Sœurs lors d’une alerte Mode Diwall.
  final bool alertSistersOnAttention;

  /// Affiche des sœurs « à proximité » simulées (aperçu UX tant que pas d’API).
  final bool demoNearbyEnabled;

  final double radiusKm;

  /// Attestation : « Je confirme être une femme » (espace réservé aux femmes).
  /// Sans cette case, le réseau ne peut pas être activé.
  final bool womenOnlyAttestation;

  /// Accès effectif au réseau (activé + attestation femmes).
  bool get canUseSisterNetwork => enabled && womenOnlyAttestation;

  SisterAidProfile copyWith({
    bool? enabled,
    bool? availableToHelp,
    String? nickname,
    bool? shareApproxLocation,
    bool? alertSistersOnAttention,
    bool? demoNearbyEnabled,
    double? radiusKm,
    bool? womenOnlyAttestation,
  }) =>
      SisterAidProfile(
        enabled: enabled ?? this.enabled,
        availableToHelp: availableToHelp ?? this.availableToHelp,
        nickname: nickname ?? this.nickname,
        shareApproxLocation: shareApproxLocation ?? this.shareApproxLocation,
        alertSistersOnAttention: alertSistersOnAttention ?? this.alertSistersOnAttention,
        demoNearbyEnabled: demoNearbyEnabled ?? this.demoNearbyEnabled,
        radiusKm: radiusKm ?? this.radiusKm,
        womenOnlyAttestation: womenOnlyAttestation ?? this.womenOnlyAttestation,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'availableToHelp': availableToHelp,
        'nickname': nickname,
        'shareApproxLocation': shareApproxLocation,
        'alertSistersOnAttention': alertSistersOnAttention,
        'demoNearbyEnabled': demoNearbyEnabled,
        'radiusKm': radiusKm,
        'womenOnlyAttestation': womenOnlyAttestation,
      };

  factory SisterAidProfile.fromJson(Map<String, dynamic> json) => SisterAidProfile(
        enabled: json['enabled'] as bool? ?? false,
        availableToHelp: json['availableToHelp'] as bool? ?? false,
        nickname: json['nickname'] as String? ?? '',
        shareApproxLocation: json['shareApproxLocation'] as bool? ?? true,
        alertSistersOnAttention: json['alertSistersOnAttention'] as bool? ?? true,
        demoNearbyEnabled: json['demoNearbyEnabled'] as bool? ?? true,
        radiusKm: (json['radiusKm'] as num?)?.toDouble() ?? 2.0,
        womenOnlyAttestation: json['womenOnlyAttestation'] as bool? ?? false,
      );
}

/// Sœur du réseau (contact d’entraide — distinct du cercle famille).
class SisterPeer {
  const SisterPeer({
    required this.id,
    required this.nickname,
    required this.phone,
    this.available = true,
    this.lastLat,
    this.lastLng,
    this.lastSeenAt,
  });

  final String id;
  final String nickname;
  final String phone;
  final bool available;
  final double? lastLat;
  final double? lastLng;
  final DateTime? lastSeenAt;

  String get cleanPhone => phone.replaceAll(RegExp(r'[\s\.\-\(\)]'), '');

  SisterPeer copyWith({
    String? nickname,
    String? phone,
    bool? available,
    double? lastLat,
    double? lastLng,
    DateTime? lastSeenAt,
  }) =>
      SisterPeer(
        id: id,
        nickname: nickname ?? this.nickname,
        phone: phone ?? this.phone,
        available: available ?? this.available,
        lastLat: lastLat ?? this.lastLat,
        lastLng: lastLng ?? this.lastLng,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'phone': phone,
        'available': available,
        'lastLat': lastLat,
        'lastLng': lastLng,
        'lastSeenAt': lastSeenAt?.toIso8601String(),
      };

  factory SisterPeer.fromJson(Map<String, dynamic> json) => SisterPeer(
        id: json['id'] as String? ?? '',
        nickname: json['nickname'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        available: json['available'] as bool? ?? true,
        lastLat: (json['lastLat'] as num?)?.toDouble(),
        lastLng: (json['lastLng'] as num?)?.toDouble(),
        lastSeenAt: DateTime.tryParse(json['lastSeenAt'] as String? ?? ''),
      );
}

/// Personne « à proximité » (réseau lié ou aperçu démo / futur backend).
class NearbySister {
  const NearbySister({
    required this.id,
    required this.displayName,
    required this.distanceMeters,
    required this.isDemo,
    this.phone,
    this.available = true,
  });

  final String id;
  final String displayName;
  final double distanceMeters;
  final bool isDemo;
  final String? phone;
  final bool available;

  String get distanceLabel {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
}

class SisterAidNetwork {
  const SisterAidNetwork({
    this.profile = const SisterAidProfile(),
    this.peers = const [],
  });

  final SisterAidProfile profile;
  final List<SisterPeer> peers;

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'peers': peers.map((p) => p.toJson()).toList(),
      };

  factory SisterAidNetwork.fromJson(Map<String, dynamic> json) => SisterAidNetwork(
        profile: json['profile'] is Map
            ? SisterAidProfile.fromJson(Map<String, dynamic>.from(json['profile'] as Map))
            : const SisterAidProfile(),
        peers: (json['peers'] as List<dynamic>?)
                ?.map((e) => SisterPeer.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );

  String encode() => jsonEncode(toJson());

  static SisterAidNetwork? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return SisterAidNetwork.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  SisterAidNetwork copyWith({
    SisterAidProfile? profile,
    List<SisterPeer>? peers,
  }) =>
      SisterAidNetwork(
        profile: profile ?? this.profile,
        peers: peers ?? this.peers,
      );
}

class SisterHelpLog {
  const SisterHelpLog({
    required this.at,
    required this.peerCount,
    required this.sentDirect,
    required this.preview,
  });

  final DateTime at;
  final int peerCount;
  final int sentDirect;
  final String preview;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'peerCount': peerCount,
        'sentDirect': sentDirect,
        'preview': preview,
      };

  factory SisterHelpLog.fromJson(Map<String, dynamic> json) => SisterHelpLog(
        at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
        peerCount: json['peerCount'] as int? ?? 0,
        sentDirect: json['sentDirect'] as int? ?? 0,
        preview: json['preview'] as String? ?? '',
      );
}
