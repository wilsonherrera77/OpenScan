import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/database/app_database.dart';
import '../../services/gap_analysis_service.dart';

/// Gap Analysis Screen
///
/// Shows document gaps and missing documents analysis
class GapAnalysisScreen extends StatefulWidget {
  static const String route = '/gap-analysis';

  const GapAnalysisScreen({super.key});

  @override
  State<GapAnalysisScreen> createState() => _GapAnalysisScreenState();
}

class _GapAnalysisScreenState extends State<GapAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late GapAnalysisService _gapAnalysisService;
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;

  GapStatistics? _stats;
  List<PersonGapAnalysis>? _personGaps;
  List<FamilyGapAnalysis>? _familyGaps;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final database = Provider.of<AppDatabase>(context, listen: false);
      _gapAnalysisService = GapAnalysisService(database);

      // Load all data in parallel
      final results = await Future.wait([
        _gapAnalysisService.getGapStatistics(),
        _gapAnalysisService.analyzeAllGaps(),
        _gapAnalysisService.analyzeFamilyGaps(),
      ]);

      setState(() {
        _stats = results[0] as GapStatistics;
        _personGaps = results[1] as List<PersonGapAnalysis>;
        _familyGaps = results[2] as List<FamilyGapAnalysis>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis de Brechas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Resumen', icon: Icon(Icons.dashboard)),
            Tab(text: 'Por Persona', icon: Icon(Icons.person)),
            Tab(text: 'Por Familia', icon: Icon(Icons.family_restroom)),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analizando documentos...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildPersonTab(),
          _buildFamilyTab(),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    if (_stats == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallStats(),
          const SizedBox(height: 24),
          _buildPriorityBreakdown(),
          const SizedBox(height: 24),
          _buildMostCommonMissing(),
        ],
      ),
    );
  }

  Widget _buildOverallStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado General',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total',
                  _stats!.totalPersons.toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Completos',
                  _stats!.personsComplete.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  'Con Brechas',
                  _stats!.personsWithGaps.toString(),
                  Icons.warning,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _stats!.totalPersons > 0
                  ? _stats!.personsComplete / _stats!.totalPersons
                  : 0,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 8),
            Text(
              'Completitud promedio: ${_stats!.averageCompletionPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPriorityBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prioridades',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPriorityItem(
              'Alta',
              _stats!.highPriorityPersons,
              Colors.red,
              'Requieren atención inmediata',
            ),
            const SizedBox(height: 12),
            _buildPriorityItem(
              'Media',
              _stats!.mediumPriorityPersons,
              Colors.orange,
              'Atención recomendada',
            ),
            const SizedBox(height: 12),
            _buildPriorityItem(
              'Baja',
              _stats!.lowPriorityPersons,
              Colors.green,
              'Casi completos',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityItem(String label, int count, Color color, String description) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label ($count)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMostCommonMissing() {
    if (_stats!.mostCommonMissingDocument == null) {
      return const SizedBox();
    }

    return Card(
      color: Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Documento más faltante',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stats!.mostCommonMissingDocument!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total faltantes: ${_stats!.totalMissingDocuments}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonTab() {
    if (_personGaps == null || _personGaps!.isEmpty) {
      return const Center(
        child: Text('No hay personas para analizar'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _personGaps!.length,
      itemBuilder: (context, index) {
        final person = _personGaps![index];
        return _buildPersonCard(person);
      },
    );
  }

  Widget _buildPersonCard(PersonGapAnalysis person) {
    final priorityColor = person.priorityLevel == 'Alta'
        ? Colors.red
        : person.priorityLevel == 'Media'
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showPersonDetails(person),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: priorityColor.withOpacity(0.1),
                    child: Icon(Icons.person, color: priorityColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.personName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Familia: ${person.familyId}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      person.priorityLevel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: person.completionPercentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(priorityColor),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${person.completionPercentage.toStringAsFixed(0)}% completo',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    '${person.missingRequiredDocuments.length} faltantes',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyTab() {
    if (_familyGaps == null || _familyGaps!.isEmpty) {
      return const Center(
        child: Text('No hay familias para analizar'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _familyGaps!.length,
      itemBuilder: (context, index) {
        final family = _familyGaps![index];
        return _buildFamilyCard(family);
      },
    );
  }

  Widget _buildFamilyCard(FamilyGapAnalysis family) {
    final priorityColor = family.priorityLevel == 'Alta'
        ? Colors.red
        : family.priorityLevel == 'Media'
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showFamilyDetails(family),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.family_restroom, color: priorityColor, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Familia ${family.familyId}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      family.priorityLevel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFamilyStat('Personas', family.totalPersons.toString()),
                  _buildFamilyStat('Con Brechas', family.personsWithGaps.toString()),
                  _buildFamilyStat('Completitud', '${family.averageCompletionPercentage.toStringAsFixed(0)}%'),
                ],
              ),
              if (family.mostCommonMissingDocuments.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Documentos más faltantes:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: family.mostCommonMissingDocuments.map((doc) {
                    return Chip(
                      label: Text(doc, style: const TextStyle(fontSize: 10)),
                      backgroundColor: Colors.orange.withOpacity(0.1),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _showPersonDetails(PersonGapAnalysis person) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  person.personName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Familia: ${person.familyId}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Documentos Existentes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (person.existingDocuments.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: person.existingDocuments.map((doc) {
                      return Chip(
                        label: Text(doc, style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.green.withOpacity(0.1),
                        avatar: const Icon(Icons.check, size: 16, color: Colors.green),
                      );
                    }).toList(),
                  )
                else
                  const Text('Ninguno'),
                const SizedBox(height: 16),
                const Text(
                  'Documentos Faltantes (Requeridos)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (person.missingRequiredDocuments.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: person.missingRequiredDocuments.map((doc) {
                      return Chip(
                        label: Text(doc, style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.red.withOpacity(0.1),
                        avatar: const Icon(Icons.warning, size: 16, color: Colors.red),
                      );
                    }).toList(),
                  )
                else
                  const Text('¡Todos completos!', style: TextStyle(color: Colors.green)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFamilyDetails(FamilyGapAnalysis family) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Familia ${family.familyId}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Personas en la familia',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: family.personAnalyses.length,
                    itemBuilder: (context, index) {
                      final person = family.personAnalyses[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(Icons.person, color: Colors.blue),
                        ),
                        title: Text(person.personName),
                        subtitle: Text('${person.completionPercentage.toStringAsFixed(0)}% completo'),
                        trailing: person.missingRequiredDocuments.isNotEmpty
                            ? Chip(
                                label: Text('${person.missingRequiredDocuments.length}'),
                                backgroundColor: Colors.orange.withOpacity(0.1),
                              )
                            : const Icon(Icons.check_circle, color: Colors.green),
                        onTap: () {
                          Navigator.pop(context);
                          _showPersonDetails(person);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
