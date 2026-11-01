import 'package:flutter/material.dart';

import '../data/database_service.dart';
import '../data/models.dart';
import '../widgets/common_widgets.dart';

class TeamEditorPage extends StatefulWidget {
  final TeamRecord? team;
  const TeamEditorPage({super.key, this.team});

  @override
  State<TeamEditorPage> createState() => _TeamEditorPageState();
}

class _TeamEditorPageState extends State<TeamEditorPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _goal;
  late final TextEditingController _region;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.team?.name ?? '');
    _goal = TextEditingController(text: widget.team?.goal ?? '');
    _region = TextEditingController(text: widget.team?.region ?? 'Kanto');
  }

  @override
  void dispose() {
    _name.dispose(); _goal.dispose(); _region.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final team = TeamRecord(id: widget.team?.id, name: _name.text,
      goal: _goal.text, region: _region.text,
      status: widget.team?.status ?? TeamStatus.planned);
    try {
      await DatabaseService.instance.saveTeam(team);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.team == null ? 'Create a team' : 'Edit team')),
    body: SafeArea(child: Form(key: _form, child: ListView(
      padding: const EdgeInsets.all(20), children: [
        const SectionLabel('Team identity',
          subtitle: 'Choose a name and one clear training objective.'),
        TextFormField(controller: _name, maxLength: 40,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Team name',
              prefixIcon: Icon(Icons.shield_outlined)),
          validator: (v) => (v?.trim().length ?? 0) < 2
              ? 'Enter at least two characters.' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _region, maxLength: 40,
          decoration: const InputDecoration(labelText: 'Region / theme',
              helperText: 'e.g. Kanto, Johto, or Competitive'),
          validator: (v) => (v?.trim().isEmpty ?? true)
              ? 'Region cannot be empty.' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _goal, maxLength: 180, maxLines: 3,
          decoration: const InputDecoration(labelText: 'What is your team goal?',
              alignLabelWithHint: true, hintText: 'Train six balanced Pokémon to 100%'),
          validator: (v) => (v?.trim().isEmpty ?? true)
              ? 'Enter a goal.' : null),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: _saving ? null : _save,
          icon: const Icon(Icons.check),
          label: Text(_saving ? 'Saving...' : 'Save team')),
        const SizedBox(height: 8),
        Text('Teams and their Pokémon are saved locally on this device.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall),
      ],
    ))),
  );
}
