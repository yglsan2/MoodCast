import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/safety_circle.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/feel_good_card.dart';
import 'safety_circle_screen.dart';

/// Assistant « Protéger un enfant / un proche » — config style Life360 simplifiée.
class ProtectedSetupScreen extends StatefulWidget {
  const ProtectedSetupScreen({super.key});

  @override
  State<ProtectedSetupScreen> createState() => _ProtectedSetupScreenState();
}

class _ProtectedSetupScreenState extends State<ProtectedSetupScreen> {
  final _page = PageController();
  int _step = 0;

  final _protectedName = TextEditingController();
  bool _childMode = true;

  final _c1Name = TextEditingController();
  final _c1Phone = TextEditingController();
  SafetyRelation _c1Relation = SafetyRelation.parent;

  final _c2Name = TextEditingController();
  final _c2Phone = TextEditingController();
  SafetyRelation _c2Relation = SafetyRelation.family;

  final _c3Name = TextEditingController();
  final _c3Phone = TextEditingController();
  SafetyRelation _c3Relation = SafetyRelation.friend;

  @override
  void dispose() {
    _page.dispose();
    _protectedName.dispose();
    _c1Name.dispose();
    _c1Phone.dispose();
    _c2Name.dispose();
    _c2Phone.dispose();
    _c3Name.dispose();
    _c3Phone.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final existing = await StorageService.getSafetyCircle();
    final contacts = <SafetyContact>[];

    void addIfValid({
      required TextEditingController name,
      required TextEditingController phone,
      required SafetyRelation relation,
      required bool priority,
      required String id,
    }) {
      final p = phone.text.trim();
      if (p.isEmpty) return;
      contacts.add(SafetyContact(
        id: id,
        name: name.text.trim().isEmpty ? relation.labelFr : name.text.trim(),
        phone: p,
        relation: relation,
        priority: priority,
      ));
    }

    addIfValid(
      name: _c1Name,
      phone: _c1Phone,
      relation: _c1Relation,
      priority: true,
      id: 'setup_parent_${DateTime.now().millisecondsSinceEpoch}',
    );
    addIfValid(
      name: _c2Name,
      phone: _c2Phone,
      relation: _c2Relation,
      priority: true,
      id: 'setup_family_${DateTime.now().millisecondsSinceEpoch}',
    );
    addIfValid(
      name: _c3Name,
      phone: _c3Phone,
      relation: _c3Relation,
      priority: false,
      id: 'setup_friend_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (contacts.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoute au moins un numéro (parent ou proche).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final profile = ProtectedProfile(
      displayName: _protectedName.text.trim(),
      childFriendlyMode: _childMode,
      setupCompleted: true,
    );

    // Fusionne avec contacts déjà présents (évite d’écraser un cercle existant).
    final merged = [...existing.contacts];
    for (final c in contacts) {
      if (merged.any((e) => e.cleanPhone == c.cleanPhone)) continue;
      merged.add(c);
    }

    final groups = [
      SafetyGroup(
        id: 'group_priority',
        name: 'Urgence prioritaire',
        contactIds: merged.where((c) => c.priority).map((c) => c.id).toList(),
      ),
      SafetyGroup(
        id: 'group_circle',
        name: 'Tout le cercle',
        contactIds: merged.map((c) => c.id).toList(),
      ),
      ...existing.groups.where((g) => g.id != 'group_priority' && g.id != 'group_circle'),
    ];

    await StorageService.setSafetyCircle(
      SafetyCircleData(contacts: merged, groups: groups, profile: profile),
    );
    await StorageService.setAlertContact(
      name: contacts.first.name,
      phone: contacts.first.phone,
    );

    if (!mounted) return;
    HapticFeedback.mediumImpact();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cercle prêt'),
        content: Text(
          _childMode
              ? 'L’app est configurée pour ${_protectedName.text.trim().isEmpty ? 'ton enfant' : _protectedName.text.trim()}. '
                  'En cas de malaise ou d’endroit bizarre, un appui sur Diwall prévient d’abord les contacts prioritaires.'
              : 'Ton cercle de confiance est enregistré. Les contacts prioritaires seront alertés en premier.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _next() {
    if (_step < 2) {
      _page.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Protéger un proche'),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: List.generate(3, (i) {
                final active = i <= _step;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: active ? AppColors.error : AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _page,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _step = i),
              children: [
                _stepWho(),
                _stepPriority(),
                _stepCircle(),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: () => _page.previousPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      ),
                      child: const Text('Retour'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: Text(_step == 2 ? 'Terminer' : 'Continuer'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepWho() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        FeelGoodCard(
          gradient: AppColors.gradientSos,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comme un cercle Life360, mais pour l’urgence',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu configures le téléphone d’une petite fille, d’un ado ou d’un proche : '
                'en cas de malaise ou d’endroit bizarre, ses parents / amis prioritaires sont prévenus avec la position.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.95), height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _protectedName,
          decoration: const InputDecoration(
            labelText: 'Prénom de la personne protégée',
            hintText: 'ex. Léa',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mode enfant / ado (textes simples)'),
          subtitle: const Text('Boutons plus grands, consignes claires'),
          value: _childMode,
          onChanged: (v) => setState(() => _childMode = v),
          activeThumbColor: AppColors.error,
        ),
      ],
    );
  }

  Widget _stepPriority() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Contacts d’urgence prioritaires',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Ils sont prévenus en premier (parents, tuteur, famille proche). Au moins un numéro est recommandé.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 16),
        _contactCard(
          title: 'Priorité 1 — souvent un parent',
          nameCtrl: _c1Name,
          phoneCtrl: _c1Phone,
          relation: _c1Relation,
          onRelation: (r) => setState(() => _c1Relation = r),
        ),
        const SizedBox(height: 12),
        _contactCard(
          title: 'Priorité 2 — autre parent / famille',
          nameCtrl: _c2Name,
          phoneCtrl: _c2Phone,
          relation: _c2Relation,
          onRelation: (r) => setState(() => _c2Relation = r),
        ),
      ],
    );
  }

  Widget _stepCircle() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Élargir le cercle (optionnel)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Ami(e)s ou autres proches : alertés juste après les prioritaires.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 16),
        _contactCard(
          title: 'Ami(e) / autre proche',
          nameCtrl: _c3Name,
          phoneCtrl: _c3Phone,
          relation: _c3Relation,
          onRelation: (r) => setState(() => _c3Relation = r),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SafetyCircleScreen()),
            );
          },
          icon: const Icon(Icons.groups_rounded),
          label: const Text('Voir / enrichir le cercle complet'),
        ),
      ],
    );
  }

  Widget _contactCard({
    required String title,
    required TextEditingController nameCtrl,
    required TextEditingController phoneCtrl,
    required SafetyRelation relation,
    required ValueChanged<SafetyRelation> onRelation,
  }) {
    return FeelGoodCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: phoneCtrl,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<SafetyRelation>(
            value: relation,
            decoration: const InputDecoration(
              labelText: 'Lien',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: SafetyRelation.values
                .map(
                  (r) => DropdownMenuItem(
                    value: r,
                    child: Text('${r.emoji} ${r.labelFr}'),
                  ),
                )
                .toList(),
            onChanged: (r) {
              if (r != null) onRelation(r);
            },
          ),
        ],
      ),
    );
  }
}
