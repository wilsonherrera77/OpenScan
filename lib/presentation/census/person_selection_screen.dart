import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/person.dart';
import '../providers/auth_provider.dart';
import '../providers/census_provider.dart';
import '../auth/login_screen.dart';
import '../document_selection/document_metadata_screen.dart';

/// Person Selection Screen
/// Allows users to search and select a person from the census
class PersonSelectionScreen extends StatefulWidget {
  static const String route = '/person-selection';

  const PersonSelectionScreen({Key? key}) : super(key: key);

  @override
  State<PersonSelectionScreen> createState() => _PersonSelectionScreenState();
}

class _PersonSelectionScreenState extends State<PersonSelectionScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(LoginScreen.route);
    }
  }

  Future<void> _selectPerson(Person person) async {
    final censusProvider = Provider.of<CensusProvider>(context, listen: false);
    await censusProvider.selectPerson(person);

    if (mounted) {
      // Show confirmation and navigate to document metadata screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Persona seleccionada: ${person.fullName}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );

      // Navigate to document metadata selection screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DocumentMetadataScreen(person: person),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Persona'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<void>(
                itemBuilder: (context) => <PopupMenuEntry<void>>[
                  PopupMenuItem<void>(
                    child: Row(
                      children: const [
                        Icon(Icons.person),
                        SizedBox(width: 8),
                        Text('Usuario actual'),
                      ],
                    ),
                    enabled: false,
                  ),
                  PopupMenuItem<void>(
                    child: Text(authProvider.username ?? 'N/A'),
                    enabled: false,
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<void>(
                    child: Row(
                      children: const [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Cerrar Sesión'),
                      ],
                    ),
                    onTap: _handleLogout,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Header
          Consumer<CensusProvider>(
            builder: (context, censusProvider, child) {
              final stats = censusProvider.statistics;

              if (stats == null) {
                return const SizedBox.shrink();
              }

              return Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            icon: Icons.people,
                            label: 'Personas',
                            value: stats['total_persons'].toString(),
                          ),
                          _StatItem(
                            icon: Icons.family_restroom,
                            label: 'Familias',
                            value: stats['total_families'].toString(),
                          ),
                          _StatItem(
                            icon: Icons.description,
                            label: 'Documentos',
                            value: stats['total_documents_required'].toString(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, cédula, ID o familia...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          final censusProvider =
                              Provider.of<CensusProvider>(context, listen: false);
                          censusProvider.clearSearch();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (query) {
                final censusProvider =
                    Provider.of<CensusProvider>(context, listen: false);
                censusProvider.searchPersons(query);
              },
            ),
          ),

          const SizedBox(height: 16),

          // Person List
          Expanded(
            child: Consumer<CensusProvider>(
              builder: (context, censusProvider, child) {
                if (censusProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (censusProvider.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            censusProvider.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => censusProvider.reload(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final persons = censusProvider.persons;

                if (persons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          censusProvider.searchQuery.isEmpty
                              ? 'No hay personas en el censo'
                              : 'No se encontraron resultados para "${censusProvider.searchQuery}"',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: persons.length,
                  itemBuilder: (context, index) {
                    final person = persons[index];
                    return _PersonCard(
                      person: person,
                      onTap: () => _selectPerson(person),
                      isSelected: censusProvider.selectedPerson?.personId ==
                          person.personId,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Selected Person Info (if any)
      bottomNavigationBar: Consumer<CensusProvider>(
        builder: (context, censusProvider, child) {
          final selectedPerson = censusProvider.selectedPerson;

          if (selectedPerson == null) {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade900,
            child: SafeArea(
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Persona seleccionada:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          selectedPerson.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => censusProvider.clearSelection(),
                    child: const Text(
                      'Cambiar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Statistics Item Widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

/// Person Card Widget
class _PersonCard extends StatelessWidget {
  final Person person;
  final VoidCallback onTap;
  final bool isSelected;

  const _PersonCard({
    required this.person,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected ? Colors.green.shade900 : null,
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            person.fullName.isNotEmpty ? person.fullName[0].toUpperCase() : '?',
          ),
        ),
        title: Text(
          person.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (person.documentNumber != null)
              Text('Cédula: ${person.documentNumber}'),
            Text('ID: ${person.personId}'),
            Text('Familia: ${person.familyId}'),
            if (person.requiredDocumentsCount > 0)
              Text(
                '${person.requiredDocumentsCount} documentos requeridos',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade300,
                ),
              ),
          ],
        ),
        trailing: Icon(
          isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
          color: isSelected ? Colors.white : null,
        ),
        onTap: onTap,
      ),
    );
  }
}
