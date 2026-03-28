import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/goal_service.dart';
import '../models/goal_model.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return StreamBuilder<List<Goal>>(
      stream: GoalService().goalsStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allGoals = snapshot.data ?? [];
        final activeGoals = allGoals.where((g) => !g.completed).toList();
        final completedGoals = allGoals.where((g) => g.completed).toList();
        final totalSaved = allGoals.fold<double>(
          0,
          (sum, g) => sum + g.savedAmount,
        );
        final totalTarget = activeGoals.fold<double>(
          0,
          (sum, g) => sum + g.targetAmount,
        );

        Goal? closestGoal;
        if (activeGoals.isNotEmpty) {
          closestGoal = activeGoals.reduce(
            (a, b) => a.progressPercent >= b.progressPercent ? a : b,
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola, ${user.displayName?.split(' ').first ?? 'usuario'}! 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getMotivationalMessage(activeGoals.length),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.savings,
                      label: 'Total ahorrado',
                      value: '\$${totalSaved.toStringAsFixed(0)}',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.flag,
                      label: 'Metas activas',
                      value: '${activeGoals.length}',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.emoji_events,
                      label: 'Metas cumplidas',
                      value: '${completedGoals.length}',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.track_changes,
                      label: 'Por alcanzar',
                      value:
                          '\$${(totalTarget - totalSaved).clamp(0, double.infinity).toStringAsFixed(0)}',
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              if (closestGoal != null) ...[
                const Text(
                  'Meta más cercana',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _ClosestGoalCard(goal: closestGoal),
                const SizedBox(height: 28),
              ],

              if (activeGoals.isNotEmpty) ...[
                const Text(
                  'Resumen de metas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...activeGoals.map((goal) => _MiniGoalRow(goal: goal)),
              ],

              if (activeGoals.isEmpty && completedGoals.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        Icons.savings_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aún no tienes metas.\n¡Crea tu primera meta!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getMotivationalMessage(int activeCount) {
    if (activeCount == 0) return 'Comienza creando tu primera meta de ahorro.';
    if (activeCount == 1) return 'Tienes 1 meta activa. ¡Sigue adelante!';
    return 'Tienes $activeCount metas activas. ¡Vas muy bien!';
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _ClosestGoalCard extends StatelessWidget {
  final Goal goal;

  const _ClosestGoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${goal.progressPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: goal.progressPercent / 100,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${goal.savedAmount.toStringAsFixed(0)} de \$${goal.targetAmount.toStringAsFixed(0)} · Para ${goal.estimatedDate}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniGoalRow extends StatelessWidget {
  final Goal goal;

  const _MiniGoalRow({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: goal.progressPercent / 100,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${goal.progressPercent.toStringAsFixed(0)}%',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
