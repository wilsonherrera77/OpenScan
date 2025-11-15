import 'package:flutter/material.dart';
import '../../../domain/entities/assignment.dart';
import '../../../domain/entities/user_profile.dart';

/// Productivity Card Widget
/// Shows user's productivity metrics
class ProductivityCard extends StatelessWidget {
  final ProductivityMetrics? metrics;
  final bool isLoading;

  const ProductivityCard({
    Key? key,
    this.metrics,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (metrics == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.analytics, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Mi Productividad',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Metrics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _MetricTile(
                  icon: Icons.description,
                  label: 'Documentos',
                  value: '${metrics!.totalDocuments}',
                  color: Colors.blue,
                ),
                _MetricTile(
                  icon: Icons.people,
                  label: 'Personas',
                  value: '${metrics!.totalPersons}',
                  color: Colors.green,
                ),
                _MetricTile(
                  icon: Icons.star,
                  label: 'Calidad Prom.',
                  value: '${metrics!.avgQualityScore.toStringAsFixed(1)}%',
                  color: Colors.orange,
                ),
                _MetricTile(
                  icon: Icons.speed,
                  label: 'Docs/Hora',
                  value: metrics!.documentsPerHour.toStringAsFixed(1),
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Team Statistics Card Widget
/// Shows team-wide statistics (Admin only)
class TeamStatisticsCard extends StatelessWidget {
  final TeamStatistics? stats;
  final bool isLoading;

  const TeamStatisticsCard({
    Key? key,
    this.stats,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.groups, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Estadísticas del Equipo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Progress Overview
            _ProgressOverview(stats: stats!),

            const Divider(height: 32),

            // Document Stats
            _DocumentStats(stats: stats!),

            if (stats!.topDigitizers.isNotEmpty) ...[
              const Divider(height: 32),
              _TopDigitizers(digitizers: stats!.topDigitizers),
            ],
          ],
        ),
      ),
    );
  }
}

/// Assignment Summary Card Widget
/// Shows assignment counts by status
class AssignmentSummaryCard extends StatelessWidget {
  final List<PersonAssignment> assignments;
  final VoidCallback? onViewAll;

  const AssignmentSummaryCard({
    Key? key,
    required this.assignments,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pending = assignments.where((a) => a.isPending).length;
    final inProgress = assignments.where((a) => a.isInProgress).length;
    final completed = assignments.where((a) => a.isCompleted).length;
    final total = assignments.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.assignment, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Mis Asignaciones',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('Ver Todas'),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Status Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _MetricTile(
                  icon: Icons.pending_actions,
                  label: 'Pendientes',
                  value: '$pending',
                  color: Colors.grey,
                ),
                _MetricTile(
                  icon: Icons.play_arrow,
                  label: 'En Progreso',
                  value: '$inProgress',
                  color: Colors.blue,
                ),
                _MetricTile(
                  icon: Icons.check_circle,
                  label: 'Completadas',
                  value: '$completed',
                  color: Colors.green,
                ),
                _MetricTile(
                  icon: Icons.folder,
                  label: 'Total',
                  value: '$total',
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Metric Tile Widget
class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Progress Overview Widget
class _ProgressOverview extends StatelessWidget {
  final TeamStatistics stats;

  const _ProgressOverview({required this.stats});

  @override
  Widget build(BuildContext context) {
    final completionPercent = stats.completionPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progreso General',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: completionPercent / 100,
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 12,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${completionPercent.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SmallStat(
              label: 'Pendientes',
              value: '${stats.pendingAssignments}',
              color: Colors.grey,
            ),
            _SmallStat(
              label: 'En Progreso',
              value: '${stats.inProgressAssignments}',
              color: Colors.blue,
            ),
            _SmallStat(
              label: 'Completadas',
              value: '${stats.completedAssignments}',
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }
}

/// Document Stats Widget
class _DocumentStats extends StatelessWidget {
  final TeamStatistics stats;

  const _DocumentStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documentos Digitalizados',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SmallStat(
              label: 'Hoy',
              value: '${stats.totalDocumentsToday}',
              color: Colors.orange,
            ),
            _SmallStat(
              label: 'Esta Semana',
              value: '${stats.totalDocumentsWeek}',
              color: Colors.blue,
            ),
            _SmallStat(
              label: 'Este Mes',
              value: '${stats.totalDocumentsMonth}',
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }
}

/// Top Digitizers Widget
class _TopDigitizers extends StatelessWidget {
  final List<TopDigitizer> digitizers;

  const _TopDigitizers({required this.digitizers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Digitalizadores',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 12),
        ...digitizers.take(5).map((digitizer) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 20,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(digitizer.username),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${digitizer.count} docs',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

/// Small Stat Widget
class _SmallStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SmallStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}

/// Welcome Header Widget
class WelcomeHeader extends StatelessWidget {
  final UserProfile userProfile;

  const WelcomeHeader({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getRoleColor(userProfile.role).withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getRoleColor(userProfile.role),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getRoleIcon(userProfile.role),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido, ${userProfile.username}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userProfile.role.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${userProfile.documentsDigitized} documentos digitalizados',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.digitalizador:
        return Icons.document_scanner;
      case UserRole.revisor:
        return Icons.fact_check;
      case UserRole.viewer:
        return Icons.visibility;
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.blue;
      case UserRole.digitalizador:
        return Colors.green;
      case UserRole.revisor:
        return Colors.orange;
      case UserRole.viewer:
        return Colors.purple;
    }
  }
}
