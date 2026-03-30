import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/goal_service.dart';
import '../models/goal_model.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _getMotivationalMessage(int activeCount, double totalSaved) {
    if (activeCount == 0 && totalSaved == 0) {
      return 'Comienza creando tu primera meta de ahorro ';
    }
    if (totalSaved == 0)
      return '¡Tienes $activeCount meta${activeCount > 1 ? 's' : ''} lista${activeCount > 1 ? 's' : ''}! Empieza a ahorrar hoy.';
    if (activeCount == 0) return '¡Increíble! Has completado todas tus metas ';
    final messages = [
      'Cada peso cuenta. ¡Sigue así! ',
      'La constancia es la clave del éxito financiero.',
      'Pequeños pasos llevan a grandes logros. ',
      'Tu futuro yo te lo agradecerá. ',
      'Ahorrar hoy es libertad mañana. ',
    ];
    return messages[DateTime.now().day % messages.length];
  }

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
              // Saludo con hora
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.base, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()}, ${user.displayName?.split(' ').first ?? 'usuario'} ',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getMotivationalMessage(activeGoals.length, totalSaved),
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tarjetas de resumen
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.savings,
                      label: 'Total ahorrado',
                      value: '\$${totalSaved.toStringAsFixed(0)}',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.flag,
                      label: 'Metas activas',
                      value: '${activeGoals.length}',
                      color: AppColors.button,
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
                      color: Colors.amber[700]!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.track_changes,
                      label: 'Por alcanzar',
                      value:
                          '\$${(totalTarget - totalSaved).clamp(0, double.infinity).toStringAsFixed(0)}',
                      color: AppColors.soft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Meta más cercana
              if (closestGoal != null) ...[
                Row(
                  children: [
                    const Text(
                      'Meta más cercana',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${closestGoal.levels.where((l) => !l.completed).length} niveles restantes',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _ClosestGoalCard(goal: closestGoal),
                const SizedBox(height: 24),
              ],

              // Resumen de metas
              if (activeGoals.isNotEmpty) ...[
                const Text(
                  'Resumen de metas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 10),
                ...activeGoals.map((goal) => _MiniGoalRow(goal: goal)),
              ],

              if (allGoals.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        Icons.savings_outlined,
                        size: 64,
                        color: AppColors.soft.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Aún no tienes metas.',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '¡Crea tu primera meta de ahorro!',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
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
        gradient: const LinearGradient(
          colors: [AppColors.button, AppColors.primary],
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
                    color: AppColors.white,
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
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${goal.progressPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: goal.progressPercent / 100,
            backgroundColor: AppColors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${goal.savedAmount.toStringAsFixed(0)} de \$${goal.targetAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
              Text(
                'Para: ${goal.estimatedDate}',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkText,
                  ),
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
