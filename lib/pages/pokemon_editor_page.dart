import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/database_service.dart';
import '../data/models.dart';
import '../widgets/common_widgets.dart';

class PokemonEditorPage extends StatefulWidget {
  final int teamId;
  final PokeMember? member;
  const PokemonEditorPage({super.key, required this.teamId, this.member});

  @override
  State<PokemonEditorPage> createState() => _PokemonEditorPageState();
}

class _PokemonEditorPageState extends State<PokemonEditorPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _species;
  late final TextEditingController _nickname;
  late final TextEditingController _role;
  late final TextEditingController _level;
  late final TextEditingController _notes;
  late PokeType _type;
  late double _progress;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.member;
    _species = TextEditingController(text: p?.species ?? '');
    _nickname = TextEditingController(text: p?.nickname ?? '');
    _role = TextEditingController(text: p?.role ?? 'Attacker');
    _level = TextEditingController(text: '${p?.level ?? 5}');
    _notes = TextEditingController(text: p?.notes ?? '');
    _type = p?.type ?? PokeType.fire;
    _progress = (p?.progress ?? 0).toDouble();
  }

  @override
  void dispose() {
    _species.dispose(); _nickname.dispose(); _role.dispose();
    _level.dispose(); _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      await DatabaseService.instance.saveMember(PokeMember(
        id: widget.member?.id,
        teamId: widget.teamId,
        species: _species.text,
        nickname: _nickname.text,
        type: _type,
        role: _role.text,
        level: int.parse(_level.text),
        progress: _progress.round(),
        notes: _notes.text,
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.member == null ? 'Recruit Pokémon' : 'Edit Pokémon')),
    body: SafeArea(child: Form(key: _form, child: ListView(
      padding: const EdgeInsets.all(20), children: [
        const SectionLabel('Pokémon profile',
            subtitle: 'All entries are entered manually and stored offline.'),
        TextFormField(controller: _species, maxLength: 30,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Species *',
              hintText: 'e.g. Pikachu'),
          validator: (v) => (v?.trim().length ?? 0) < 2
              ? 'Enter a species with at least 2 characters.' : null),
        const SizedBox(height: 10),
        TextFormField(controller: _nickname, maxLength: 28,
          decoration: const InputDecoration(labelText: 'Nickname (optional)')),
        const SizedBox(height: 10),
        DropdownButtonFormField<PokeType>(
          // ignore: deprecated_member_use
          value: _type,
          decoration: const InputDecoration(labelText: 'Primary type *'),
          isExpanded: true,
          items: PokeType.values.map((type) => DropdownMenuItem<PokeType>(
            value: type, child: Row(children: [
              Text(typeEmoji(type)), const SizedBox(width: 9), Text(type.label),
            ]),
          )).toList(),
          onChanged: (v) { if (v != null) setState(() => _type = v); },
        ),
        const SizedBox(height: 17),
        TextFormField(controller: _role, maxLength: 50,
          decoration: const InputDecoration(labelText: 'Role',
              helperText: 'e.g. Attacker, Tank, Support, Undecided'),
          validator: (v) => (v?.trim().isEmpty ?? true)
              ? 'Enter a role.' : null),
        const SizedBox(height: 10),
        TextFormField(controller: _level,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Level (1–100)'),
          validator: (v) {
            final n = int.tryParse(v?.trim() ?? '');
            return n == null || n < 1 || n > 100 ? 'Enter a level from 1 to 100.' : null;
          },
        ),
        const SizedBox(height: 10),
        Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('TRAINING PROGRESS', style: TextStyle(fontWeight: FontWeight.w800)),
              Text('${_progress.round()}%', style: const TextStyle(
                  color: brandYellow, fontWeight: FontWeight.w900)),
            ]),
            Slider(
              value: _progress, min: 0, max: 100, divisions: 20,
              label: '${_progress.round()}%',
              onChanged: (v) => setState(() => _progress = v),
            ),
            Text('Move the slider after training. Reaching 100% counts as ready.',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ))),
        const SizedBox(height: 10),
        TextFormField(controller: _notes, maxLines: 4, maxLength: 240,
          decoration: const InputDecoration(labelText: 'Strategy notes',
            alignLabelWithHint: true,
            hintText: 'Moves, strengths, weaknesses, or training plans')),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Saving...' : 'Save Pokémon')),
      ],
    ))),
  );
}
