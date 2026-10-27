import 'package:flutter_test/flutter_test.dart';
import 'package:moodcast_worldflow/models/mood_safe_session.dart';
import 'package:moodcast_worldflow/models/safety_circle.dart';
import 'package:moodcast_worldflow/models/sister_aid.dart';

void main() {
  group('DiffusionProfile', () {
    test('encode/decode roundtrip', () {
      const p = DiffusionProfile(
        notifyPriorityFirst: true,
        notifyFullCircle: false,
        notifySisterAid: true,
        attentionHoldSeconds: 5,
        classicCancelSeconds: 10,
        defaultTrigger: AttentionTriggerStyle.classicCancelWindow,
      );
      final decoded = DiffusionProfile.tryDecode(p.encode());
      expect(decoded.attentionHoldSeconds, 5);
      expect(decoded.classicCancelSeconds, 10);
      expect(decoded.notifyFullCircle, false);
      expect(decoded.defaultTrigger, AttentionTriggerStyle.classicCancelWindow);
    });

    test('tryDecode invalid returns defaults', () {
      final d = DiffusionProfile.tryDecode('{not-json');
      expect(d.attentionHoldSeconds, 3);
      expect(d.defaultTrigger, AttentionTriggerStyle.deadManSwitch);
    });

    test('attentionHoldDuration clamps', () {
      const low = DiffusionProfile(attentionHoldSeconds: 1);
      expect(low.attentionHoldDuration.inSeconds, 2);
      const high = DiffusionProfile(attentionHoldSeconds: 99);
      expect(high.attentionHoldDuration.inSeconds, 10);
    });
  });

  group('SafetyCircle', () {
    test('priority recipients first', () {
      final data = SafetyCircleData(
        contacts: [
          const SafetyContact(
            id: 'a',
            name: 'Ami',
            phone: '+33600000001',
            relation: SafetyRelation.friend,
            priority: false,
          ),
          const SafetyContact(
            id: 'b',
            name: 'Maman',
            phone: '+33600000002',
            relation: SafetyRelation.parent,
            priority: true,
          ),
        ],
      );
      final list = data.resolveAlertRecipients();
      expect(list.first.name, 'Maman');
      expect(list.length, 2);
    });
  });

  group('SisterAidProfile', () {
    test('canUseSisterNetwork requires attestation', () {
      const no = SisterAidProfile(enabled: true, womenOnlyAttestation: false);
      expect(no.canUseSisterNetwork, false);
      const yes = SisterAidProfile(enabled: true, womenOnlyAttestation: true);
      expect(yes.canUseSisterNetwork, true);
    });
  });

  group('MoodSafeAlertSession', () {
    test('sentCount counts direct SMS', () {
      final s = MoodSafeAlertSession(
        id: '1',
        startedAt: DateTime(2026, 1, 1),
        message: 'test',
        deliveries: const [
          AlertDeliveryAck(
            id: '1',
            label: 'A',
            phone: '1',
            layer: AlertLayer.priority,
            status: DeliveryStatus.sentDirect,
          ),
          AlertDeliveryAck(
            id: '2',
            label: 'B',
            phone: '2',
            layer: AlertLayer.circle,
            status: DeliveryStatus.failed,
          ),
        ],
      );
      expect(s.sentCount, 1);
      expect(s.notifiedOrPreparedCount, 1);
      final round = MoodSafeAlertSession.tryDecode(s.encode());
      expect(round?.id, '1');
      expect(round?.sentCount, 1);
    });
  });
}
