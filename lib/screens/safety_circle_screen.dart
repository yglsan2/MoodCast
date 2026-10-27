import 'package:flutter/material.dart';

import '../models/safety_circle.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/feel_good_card.dart';
import '../widgets/gradient_app_bar.dart';
import 'protected_setup_screen.dart';

/// Cercle de confiance style Life360 : priorité + rôles famille / amis / parents.
class SafetyCircleScreen extends StatefulWidget {
  const SafetyCircleScreen({super.key});

  @override
  State<SafetyCircleScreen> createState() => _SafetyCircleScreenState();
}

class _SafetyCircleScreenState extends State<SafetyCircleScreen> {
  SafetyCircleData _data = const SafetyCircleData();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await StorageService.getSafetyCircle();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  Future<void> _persist(SafetyCircleData data) async {
    await StorageService.setSafetyCircle(data);
    if (data.contacts.isNotEmpty) {
      final priority = data.priorityContacts;
      final c0 = priority.isNotEmpty ? priority.first : data.contacts.first;
      await StorageService.setAlertContact(name: c0.name, phone: c0.phone);
      final phones = data.resolveAlertRecipients();
      await StorageService.setMoodSafePhones(
        phone2: phones.length > 1 ? phones[1].phone : '',
        phone3: phones.length > 2 ? phones[2].phone : '',
      );
    }
    if (!mounted) return;
    setState(() => _data = data);
  }

  Future<void> _addOrEditContact({SafetyContact? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    var relation = existing?.relation ?? SafetyRelation.parent;
    var priority = existing?.priority ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Ajouter au cercle' : 'Modifier le contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
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
                    if (r != null) setLocal(() => relation = r);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Contact prioritaire'),
                  subtitle: const Text('Alerté en premier en urgence'),
                  value: priority,
                  onChanged: (v) => setLocal(() => priority = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim().isEmpty ? relation.labelFr : nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    if (phone.isEmpty) return;

    final contacts = [..._data.contacts];
    if (existing == null) {
      final id = 'c_${DateTime.now().millisecondsSinceEpoch}';
      contacts.add(SafetyContact(
        id: id,
        name: name,
        phone: phone,
        relation: relation,
        priority: priority,
      ));
      var groups = [..._data.groups];
      if (groups.isEmpty) {
        groups = [
          SafetyGroup(id: 'group_default', name: 'Cercle de confiance', contactIds: [id]),
        ];
      } else {
        final g0 = groups.first;
        groups[0] = g0.copyWith(contactIds: [...g0.contactIds, id]);
      }
      await _persist(_data.copyWith(contacts: contacts, groups: groups));
    } else {
      final i = contacts.indexWhere((c) => c.id == existing.id);
      if (i >= 0) {
        contacts[i] = SafetyContact(
          id: existing.id,
          name: name,
          phone: phone,
          relation: relation,
          priority: priority,
        );
        await _persist(_data.copyWith(contacts: contacts));
      }
    }
  }

  Future<void> _togglePriority(SafetyContact c) async {
    final contacts = _data.contacts
        .map((x) => x.id == c.id ? x.copyWith(priority: !x.priority) : x)
        .toList();
    await _persist(_data.copyWith(contacts: contacts));
  }

  Future<void> _deleteContact(SafetyContact c) async {
    final contacts = _data.contacts.where((x) => x.id != c.id).toList();
    final groups = _data.groups
        .map((g) => g.copyWith(contactIds: g.contactIds.where((id) => id != c.id).toList()))
        .toList();
    await _persist(_data.copyWith(contacts: contacts, groups: groups));
  }

  @override
  Widget build(BuildContext context) {
    final byRel = _data.contactsByRelation();
    final profile = _data.profile;

    return Scaffold(
      appBar: const GradientAppBar(
        title: 'Cercle de confiance',
        gradient: AppColors.gradientSos,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditContact(),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Ajouter'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                FeelGoodCard(
                  margin: EdgeInsets.zero,
                  gradient: AppColors.gradientSos,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName.isEmpty
                            ? 'Ton cercle d’urgence'
                            : 'Cercle de ${profile.displayName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Les contacts prioritaires ★ sont prévenus en premier, '
                        'puis famille, amis et autres proches — avec la position.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          height: 1.4,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProtectedSetupScreen()),
                          );
                          _load();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                        icon: const Icon(Icons.child_care_rounded),
                        label: const Text('Assistant : protéger un enfant'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_data.contacts.isEmpty)
                  FeelGoodCard(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Aucun contact. Lance l’assistant ou ajoute un parent / ami.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else ...[
                  _sectionTitle(
                    '★ Urgence prioritaire',
                    '${_data.priorityContacts.length} contact(s)',
                  ),
                  if (_data.priorityContacts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Marque au moins un parent ou proche en prioritaire.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    )
                  else
                    ..._data.priorityContacts.map(_contactTile),
                  const SizedBox(height: 8),
                  ..._relationSections(byRel),
                ],
              ],
            ),
    );
  }

  List<Widget> _relationSections(Map<SafetyRelation, List<SafetyContact>> byRel) {
    final out = <Widget>[];
    for (final rel in SafetyRelation.values) {
      final others = byRel[rel]!.where((c) => !c.priority).toList();
      if (others.isEmpty) continue;
      out.add(_sectionTitle('${rel.emoji} ${rel.labelFr}', '${others.length}'));
      out.addAll(others.map(_contactTile));
      out.add(const SizedBox(height: 8));
    }
    return out;
  }

  Widget _sectionTitle(String title, String trailing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          Text(trailing, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _contactTile(SafetyContact c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FeelGoodCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: CircleAvatar(
            backgroundColor: (c.priority ? AppColors.error : AppColors.primary).withValues(alpha: 0.15),
            child: Text(c.relation.emoji),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              if (c.priority) ...[
                const SizedBox(width: 6),
                const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
              ],
            ],
          ),
          subtitle: Text('${c.relation.labelFr} · ${c.phone}'),
          trailing: PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') _addOrEditContact(existing: c);
              if (v == 'priority') _togglePriority(c);
              if (v == 'delete') _deleteContact(c);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Modifier')),
              PopupMenuItem(
                value: 'priority',
                child: Text(c.priority ? 'Retirer la priorité' : 'Mettre en prioritaire'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
          ),
          onTap: () => _addOrEditContact(existing: c),
        ),
      ),
    );
  }
}
