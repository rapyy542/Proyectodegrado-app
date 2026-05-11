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
      return 'Comienza creando tu primera meta de ahorro 🚀';
    }
    if (totalSaved == 0) {
      return '¡Tienes $activeCount meta${activeCount > 1 ? 's' : ''} lista${activeCount > 1 ? 's' : ''}! Empieza a ahorrar hoy.';
    }
    if (activeCount == 0)
      return '¡Increíble! Has completado todas tus metas 🏆';
    final messages = [
      'Cada peso cuenta. ¡Sigue así! 💪',
      'La constancia es la clave del éxito financiero.',
      'Pequeños pasos llevan a grandes logros. 🌟',
      'Tu futuro yo te lo agradecerá. 🙌',
      'Ahorrar hoy es libertad mañana. 🕊️',
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
              // ── Tarjeta de saludo ──
              _FadeSlideIn(
                delay: 0,
                child: _GreetingCard(
                  greeting: _getGreeting(),
                  firstName: user.displayName?.split(' ').first ?? 'usuario',
                  message: _getMotivationalMessage(
                    activeGoals.length,
                    totalSaved,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Tarjetas de resumen (con contadores animados) ──
              _FadeSlideIn(
                delay: 80,
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.savings_rounded,
                        label: 'Total ahorrado',
                        value: totalSaved,
                        prefix: '\$',
                        color: AppColors.primary,
                        gradientColors: [AppColors.primary, AppColors.button],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.flag_rounded,
                        label: 'Metas activas',
                        value: activeGoals.length.toDouble(),
                        prefix: '',
                        color: AppColors.button,
                        gradientColors: [AppColors.button, AppColors.soft],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _FadeSlideIn(
                delay: 160,
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.emoji_events_rounded,
                        label: 'Metas cumplidas',
                        value: completedGoals.length.toDouble(),
                        prefix: '',
                        color: Colors.amber[700]!,
                        gradientColors: [Colors.amber, Colors.orange],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.track_changes_rounded,
                        label: 'Por alcanzar',
                        value: (totalTarget - totalSaved).clamp(
                          0,
                          double.infinity,
                        ),
                        prefix: '\$',
                        color: AppColors.soft,
                        gradientColors: [AppColors.soft, AppColors.accent],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Meta más cercana ──
              if (closestGoal != null) ...[
                _FadeSlideIn(
                  delay: 240,
                  child: Row(
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
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.button.withValues(alpha: 0.15),
                              AppColors.accent.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.button.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          '${closestGoal.levels.where((l) => !l.completed).length} niveles restantes',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _FadeSlideIn(
                  delay: 300,
                  child: _ClosestGoalCard(goal: closestGoal),
                ),
                const SizedBox(height: 24),
              ],

              // ── Resumen de todas las metas ──
              if (activeGoals.isNotEmpty) ...[
                _FadeSlideIn(
                  delay: 360,
                  child: const Text(
                    'Resumen de metas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ...activeGoals.asMap().entries.map(
                  (e) => _FadeSlideIn(
                    delay: 400 + e.key * 60,
                    child: _MiniGoalRow(goal: e.value),
                  ),
                ),
              ],

              // ── Estado vacío ──
              if (allGoals.isEmpty)
                _FadeSlideIn(
                  delay: 200,
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.button.withValues(alpha: 0.12),
                                AppColors.accent.withValues(alpha: 0.12),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.savings_outlined,
                            size: 52,
                            color: AppColors.button.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aún no tienes metas.',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '¡Crea tu primera meta de ahorro!',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// WIDGET DE ANIMACIÓN: Fade + Slide escalonado
// ─────────────────────────────────────────────
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delay; // milisegundos de retraso

  const _FadeSlideIn({required this.child, required this.delay});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────
// TARJETA DE SALUDO
// ─────────────────────────────────────────────
class _GreetingCard extends StatelessWidget {
  final String greeting;
  final String firstName;
  final String message;

  const _GreetingCard({
    required this.greeting,
    required this.firstName,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.base, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, $firstName 👋',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TARJETA DE RESUMEN con contador animado
// ─────────────────────────────────────────────
class _SummaryCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final double value;
  final String prefix;
  final Color color;
  final List<Color> gradientColors;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.prefix,
    required this.color,
    required this.gradientColors,
  });

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _countAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _countAnim = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _scaleAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: widget.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradientColors.first.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: AppColors.white, size: 20),
            ),
            const SizedBox(height: 10),
            // Contador animado
            AnimatedBuilder(
              animation: _countAnim,
              builder: (_, __) => Text(
                '${widget.prefix}${_countAnim.value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TARJETA DE META MÁS CERCANA
// ─────────────────────────────────────────────
class _ClosestGoalCard extends StatefulWidget {
  final Goal goal;
  const _ClosestGoalCard({required this.goal});

  @override
  State<_ClosestGoalCard> createState() => _ClosestGoalCardState();
}

class _ClosestGoalCardState extends State<_ClosestGoalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressAnim = Tween<double>(
      begin: 0,
      end: widget.goal.progressPercent / 100,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.button, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.button.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.goal.title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _progressAnim,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(_progressAnim.value * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AnimatedBuilder(
              animation: _progressAnim,
              builder: (_, __) => LinearProgressIndicator(
                value: _progressAnim.value,
                backgroundColor: AppColors.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accent,
                ),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${widget.goal.savedAmount.toStringAsFixed(0)} de \$${widget.goal.targetAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
              if (widget.goal.estimatedDate.isNotEmpty)
                Text(
                  'Para: ${widget.goal.estimatedDate}',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.75),
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

// ─────────────────────────────────────────────
// FILA DE META EN RESUMEN con barra animada
// ─────────────────────────────────────────────
class _MiniGoalRow extends StatefulWidget {
  final Goal goal;
  const _MiniGoalRow({required this.goal});

  @override
  State<_MiniGoalRow> createState() => _MiniGoalRowState();
}

class _MiniGoalRowState extends State<_MiniGoalRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _progressAnim = Tween<double>(
      begin: 0,
      end: widget.goal.progressPercent / 100,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.goal.progressPercent;
    final barColor = progress >= 75
        ? Colors.green
        : progress >= 40
        ? AppColors.button
        : AppColors.soft;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.soft.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.goal.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: AnimatedBuilder(
                      animation: _progressAnim,
                      builder: (_, __) => LinearProgressIndicator(
                        value: _progressAnim.value,
                        minHeight: 7,
                        backgroundColor: AppColors.background,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            AnimatedBuilder(
              animation: _progressAnim,
              builder: (_, __) => Text(
                '${(_progressAnim.value * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: barColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
