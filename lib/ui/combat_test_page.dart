import 'dart:math';
import 'package:flutter/material.dart';
import 'package:combat_sys/combat_sys.dart';
import 'package:combat_sys/utils/file_saver.dart';

// Omitting IndividualFightLog and other classes for brevity as they are unchanged.
class IndividualFightLog {
  final Combatant c1, c2;
  final CombatResult result;
  final CombatStyle c1Style, c2Style;
  IndividualFightLog({ required this.c1, required this.c2, required this.result, required this.c1Style, required this.c2Style });
}


class CombatTestPage extends StatefulWidget {
  const CombatTestPage({super.key});
  @override
  State<CombatTestPage> createState() => _CombatTestPageState();
}

class _CombatTestPageState extends State<CombatTestPage> {
  late GameSettings _settings;
  late CombatantFactory _factory;
  late CombatSystem _combatSystem;

  int _selectedTestType = 0;
  CombatStyle _c1Style = CombatStyle.None, _c2Style = CombatStyle.None;
  int _numFights = 100;
  double _g1MinExp = 1000, _g1MaxExp = 1500;
  double _g2MinExp = 1000, _g2MaxExp = 1500;
  bool _isRunning = false;
  Map<CombatResultType, int> _results = {};
  List<IndividualFightLog> _fightLogs = [];
  List<bool> _isPanelExpanded = [];
  double _progress = 0.0;
  String _reportSummary = '';
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _settings = GameSettings();
    _updateSystems();
  }

  void _updateSystems() => setState(() {
    _factory = CombatantFactory(settings: _settings);
    _combatSystem = CombatSystem(settings: _settings);
  });

  Future<void> _runSimulations() async {
    setState(() {
      _isRunning = true;
      _results = { for (var v in CombatResultType.values) v: 0 };
      _fightLogs.clear();
      _progress = 0.0;
    });

    await Future(() {
      for (int i = 0; i < _numFights; i++) {
        Player c1 = _factory.createRandomPlayer('Player1-${i+1}', _g1MinExp, _g1MaxExp, style: _c1Style);
        Combatant c2 = (_selectedTestType == 0)
            ? _factory.createRandomMonster('Monster-${i+1}', _g2MinExp, _g2MaxExp, _g2MinExp, _g2MaxExp, style: _c2Style)
            : _factory.createRandomPlayer('Player2-${i+1}', _g2MinExp, _g2MaxExp, style: _c2Style);

        var result = _combatSystem.fight(c1, c2, c1Style: _c1Style, c2Style: _c2Style);
        _results[result.type] = (_results[result.type] ?? 0) + 1;
        _fightLogs.add(IndividualFightLog(c1: c1, c2: c2, result: result, c1Style: _c1Style, c2Style: _c2Style));
        if (i % 10 == 0) setState(() => _progress = (i + 1) / _numFights);
      }
    });

    _isPanelExpanded = List.generate(_fightLogs.length, (_) => false);
    setState(() { _isRunning = false; _progress = 1.0; });
  }

  void _generateReport() {
    // This now includes all settings
    final buffer = StringBuffer();
    buffer.writeln('--- Combat Simulation Report ---');
    buffer.writeln('Date: ${DateTime.now()}');
    buffer.writeln('\n--- Game Settings Used ---');
    buffer.writeln('typeAdvantageMultiplier: ${_settings.typeAdvantageMultiplier.toStringAsFixed(2)}');
    buffer.writeln('baseHp: ${_settings.baseHp}');
    buffer.writeln('expToHpFactor: ${_settings.expToHpFactor}');
    buffer.writeln('baseDamage: ${_settings.baseDamage}');
    buffer.writeln('underdogBonus: ${_settings.underdogBonus}');
    buffer.writeln('maxTurns: ${_settings.maxTurns}');
    buffer.writeln('damageBonusNormalizer: ${_settings.damageBonusNormalizer}');
    buffer.writeln('damageReductionNormalizer: ${_settings.damageReductionNormalizer}');
    buffer.writeln('damageReductionCap: ${_settings.damageReductionCap.toStringAsFixed(2)}');
    buffer.writeln('parryVsRangedMultiplier: ${_settings.defenseParryingVsRangedMultiplier.toStringAsFixed(2)}');
    buffer.writeln('dexEvadeVsMagicMultiplier: ${_settings.defenseDexEvadeVsMagicMultiplier.toStringAsFixed(2)}');

    buffer.writeln('\n--- Summary Results ---');
    final wins1 = _results[CombatResultType.combatant1Wins] ?? 0;
    final wins2 = _results[CombatResultType.combatant2Wins] ?? 0;
    final draws = _results[CombatResultType.draw] ?? 0;
    buffer.writeln('Group 1 [${_c1Style.name}] Wins: $wins1 (${(wins1 / _numFights * 100).toStringAsFixed(1)}%)');
    buffer.writeln('Group 2 [${_c2Style.name}] Wins: $wins2 (${(wins2 / _numFights * 100).toStringAsFixed(1)}%)');
    buffer.writeln('Draws: $draws (${(draws / _numFights * 100).toStringAsFixed(1)}%)');

    _reportSummary = buffer.toString();
  }

  void _saveReport() async {
    _generateReport(); // Ensure report is up-to-date
    if (_reportSummary.isEmpty) { /* ... */ return; }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving...')));
    final success = await FileSaver.save(_reportSummary, 'combat_report_${DateTime.now().millisecondsSinceEpoch}.txt');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Report saved.' : 'Save failed.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Combat System Tester v9')),
      body: Scrollbar(
        controller: _scrollController,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildTestTypeSelector(),
            _buildSettingsCard(),
            _buildSimulationSetupCard(),
            _buildActionsCard(),
            if (_isRunning || _fightLogs.isNotEmpty) _buildResultsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestTypeSelector() {
    return Card(child: Padding(padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          Text("Tipo di Test", style: Theme.of(context).textTheme.titleMedium),
          ToggleButtons(
            isSelected: [_selectedTestType == 0, _selectedTestType == 1],
            onPressed: (index) => setState(() => _selectedTestType = index),
            borderRadius: BorderRadius.circular(8),
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Player vs Monster')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Player vs Player')),
            ],
          ),
        ],
        )));
  }

  Widget _buildSettingsCard() {
    return Card(child: ExpansionTile(
      title: const Text('Game Settings (Click to expand)'),
      initiallyExpanded: false,
      children: [
        Padding(padding: const EdgeInsets.all(12.0),
          child: Wrap(alignment: WrapAlignment.spaceAround, runSpacing: 0,
            children: [
              _buildSlider('Type Adv. Multiplier', _settings.typeAdvantageMultiplier, 1, 2, (v) => _settings.typeAdvantageMultiplier = v, isPercentage: false),
              _buildSlider('Base Damage', _settings.baseDamage, 1, 20, (v) => _settings.baseDamage = v),
              _buildSlider('Underdog Bonus', _settings.underdogBonus, 0, 100, (v) => _settings.underdogBonus = v),
              _buildSlider('Base HP', _settings.baseHp, 50, 200, (v) => _settings.baseHp = v),
              _buildSlider('Exp to HP Factor', _settings.expToHpFactor, 10, 100, (v) => _settings.expToHpFactor = v),
              _buildSlider('Max Turns', _settings.maxTurns.toDouble(), 10, 500, (v) => _settings.maxTurns = v.toInt()),
              _buildSlider('Dmg Bonus Normalizer', _settings.damageBonusNormalizer, 50, 500, (v) => _settings.damageBonusNormalizer = v),
              _buildSlider('Dmg Red. Normalizer', _settings.damageReductionNormalizer, 100, 1000, (v) => _settings.damageReductionNormalizer = v),
              _buildSlider('Dmg Red. Cap', _settings.damageReductionCap, 0, 1, (v) => _settings.damageReductionCap = v, isPercentage: true),
              _buildSlider('Parry vs Ranged Eff.', _settings.defenseParryingVsRangedMultiplier, 1, 2, (v) => _settings.defenseParryingVsRangedMultiplier = v, isPercentage: false),
              _buildSlider('Dex Evade vs Magic Eff.', _settings.defenseDexEvadeVsMagicMultiplier, 0, 1, (v) => _settings.defenseDexEvadeVsMagicMultiplier = v, isPercentage: true),
            ],
          ),
        ),
      ],
    ));
  }

  Widget _buildSimulationSetupCard() {
    return Card(child: Padding(padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Parametri Simulazione', style: Theme.of(context).textTheme.titleLarge),
          _buildSlider('Numero di Combattimenti', _numFights.toDouble(), 10, 10000, (v) => _numFights = v.toInt(), isLog: true),
          const Divider(height: 20),
          _buildCombatantSetup("Gruppo 1", _g1MinExp, _g1MaxExp, _c1Style, (style) => setState(() => _c1Style = style!), (values) => setState(() { _g1MinExp = values.start; _g1MaxExp = values.end; })),
          const Divider(height: 20),
          _buildCombatantSetup("Gruppo 2", _g2MinExp, _g2MaxExp, _c2Style, (style) => setState(() => _c2Style = style!), (values) => setState(() { _g2MinExp = values.start; _g2MaxExp = values.end; })),
        ],
        )));
  }

  Widget _buildCombatantSetup(String title, double minExp, double maxExp, CombatStyle currentStyle, Function(CombatStyle?) onStyleChanged, Function(RangeValues) onRangeChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      RangeSlider(values: RangeValues(minExp, maxExp), min: 100, max: 20000, divisions: 199, labels: RangeLabels(minExp.round().toString(), maxExp.round().toString()), onChanged: onRangeChanged),
      Text('Stile di Combattimento (Template)', style: Theme.of(context).textTheme.bodyMedium),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: CombatStyle.values.map((style) => Column(children: [
        Text(style.name),
        Radio<CombatStyle>( value: style, groupValue: currentStyle, onChanged: onStyleChanged ),
      ])).toList()),
    ]);
  }

  Widget _buildActionsCard() {
    return Card(child: Padding(padding: const EdgeInsets.all(12.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        ElevatedButton.icon(
          icon: _isRunning ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow),
          label: const Text('Avvia Simulazione'),
          onPressed: _isRunning ? null : _runSimulations,
        ),
        if (!_isRunning && _fightLogs.isNotEmpty)
          ElevatedButton.icon(icon: const Icon(Icons.save), label: const Text('Salva Report'), onPressed: _saveReport),
      ]),
    ));
  }

  Widget _buildResultsCard() {
    return Card(child: Padding(padding: const EdgeInsets.all(12.0), child: Column(children: [
      Text('Risultati', style: Theme.of(context).textTheme.titleLarge),
      if (_isRunning) Padding(padding: const EdgeInsets.all(8.0), child: LinearProgressIndicator(value: _progress)),
      if (!_isRunning && _fightLogs.isNotEmpty) ...[
        _buildSummaryResults(),
        const Divider(height: 30),
        _buildDetailedLogs(),
      ],
    ])));
  }

  Widget _buildDetailedLogs() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Log Dettagliato Combattimenti', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      if (_fightLogs.isNotEmpty)
        ExpansionPanelList(
          expansionCallback: (int index, bool isExpanded) {
            setState(() => _isPanelExpanded[index] = !isExpanded);
          },
          children: _fightLogs.asMap().entries.map<ExpansionPanel>((entry) {
            int idx = entry.key;
            IndividualFightLog log = entry.value;
            return ExpansionPanel(
              canTapOnHeader: true,
              headerBuilder: (BuildContext context, bool isExpanded) {
                return ListTile(
                  title: Text('${log.c1.name} vs ${log.c2.name}'),
                  subtitle: Text('Esito: ${log.result.type.name} in ${log.result.turns} round'),
                );
              },
              body: _buildPanelBody(log),
              isExpanded: _isPanelExpanded[idx],
            );
          }).toList(),
        ),
    ]);
  }

  Widget _buildPanelBody(IndividualFightLog log) {
    List<Skill> allSkills = Skill.values;
    final textStyle = const TextStyle(fontFamily: 'monospace', fontSize: 12);

    return Padding(
      padding: const EdgeInsets.all(8.0).copyWith(top: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  SizedBox(width: 120, child: Text('COMBATTENTE', style: textStyle.copyWith(fontWeight: FontWeight.bold))),
                  ...allSkills.map((s) => SizedBox(width: 40, child: Tooltip(message: s.name, child: Text(s.name.substring(0,3), style: textStyle.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center,))))
                ]),
                const Divider(),
                Row(children: [
                  SizedBox(width: 120, child: Text(log.c1.name, style: textStyle)),
                  ...allSkills.map((s) => SizedBox(width: 40, child: Text(log.c1.getSkill(s).toString(), style: textStyle, textAlign: TextAlign.center)))
                ]),
                Row(children: [
                  SizedBox(width: 120, child: Text(log.c2.name, style: textStyle)),
                  ...allSkills.map((s) => SizedBox(width: 40, child: Text(log.c2.getSkill(s).toString(), style: textStyle, textAlign: TextAlign.center)))
                ]),
              ],
            ),
          ),
          const Divider(height: 20),
          Text('Riepilogo Scontro:', style: Theme.of(context).textTheme.titleSmall),
          Text('Template: ${log.c1.name} [${log.c1Style.name}] vs ${log.c2.name} [${log.c2Style.name}]', style: textStyle),
          Text('HP Iniziali: ${log.result.c1InitialHp.toStringAsFixed(0)} vs ${log.result.c2InitialHp.toStringAsFixed(0)}', style: textStyle),
          Text('HP Finali: ${log.result.c1FinalHp.toStringAsFixed(0)} vs ${log.result.c2FinalHp.toStringAsFixed(0)}', style: textStyle),
          Text('HP Curati: ${log.result.c1HealedHp.toStringAsFixed(1)} vs ${log.result.c2HealedHp.toStringAsFixed(1)}', style: textStyle),
        ],
      ),
    );
  }

  Widget _buildSummaryResults() {
    final wins1 = _results[CombatResultType.combatant1Wins] ?? 0;
    final wins2 = _results[CombatResultType.combatant2Wins] ?? 0;
    final draws = _results[CombatResultType.draw] ?? 0;
    final total = wins1 + wins2 + draws;

    return Column(
      children: [
        Text('Riepilogo su $total combattimenti', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildResultColumn('Gruppo 1 Wins', wins1, total, Colors.cyan),
            _buildResultColumn('Gruppo 2 Wins', wins2, total, Colors.orange),
            _buildResultColumn('Pareggi', draws, total, Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _buildResultColumn(String title, int value, int total, Color color) {
    double percentage = total > 0 ? value / total * 100 : 0;
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color),
        ),
        Text('($value)', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, Function(double) onChanged, {bool isLog = false, bool isPercentage = false}) {
    String displayString = isPercentage ? '${(value * 100).toStringAsFixed(0)}%' : (isLog ? value.round().toString() : value.toStringAsFixed(2));
    double sliderValue = isLog ? (log(value.clamp(min, max)) - log(min)) / (log(max) - log(min)) : value;
    int? divisions = isLog ? null : (max-min)*100 ~/ 1;

    return SizedBox(width: 300, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$label: $displayString'),
      Slider(
        value: sliderValue,
        min: isLog ? 0 : min,
        max: isLog ? 1 : max,
        divisions: divisions,
        label: displayString,
        onChanged: (newValue) {
          double finalValue = isLog ? exp(log(min) + newValue * (log(max) - log(min))) : newValue;
          setState(() => onChanged(finalValue));
        },
        onChangeEnd: (v) => _updateSystems(),
      ),
    ]));
  }
}
