import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/goal_service.dart';
import '../models/goal_model.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _confettiController;
  String _sortBy = 'reciente';
  bool _confettiDone = false;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_confettiDone) {
        _confettiController.forward();
        _confettiDone = true;
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
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

        var completedGoals = (snapshot.data ?? [])
            .where((g) => g.completed)
            .toList();

        if (completedGoals.isEmpty) return const _EmptyHistory();

        if (_sortBy == 'monto') {
          completedGoals.sort(
            (a, b) => b.targetAmount.compareTo(a.targetAmount),
          );
        }

        final totalSaved = completedGoals.fold<double>(
          0,
          (sum, g) => sum + g.targetAmount,
        );

        return Stack(
          children: [
            Column(
              children: [
                _HistoryHeader(
                  count: completedGoals.length,
                  totalSaved: totalSaved,
                  sortBy: _sortBy,
                  onSortChanged: (v) => setState(() => _sortBy = v),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: completedGoals.length,
                    itemBuilder: (context, index) {
                      return _CompletedGoalCard(
                        goal: completedGoals[index],
                        index: index,
                      );
                    },
                  ),
                ),
              ],
            ),
            // Confeti
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) {
                  if (_confettiController.value == 0 ||
                      _confettiController.value == 1) {
                    return const SizedBox.shrink();
                  }
                  return CustomPaint(
                    painter: _ConfettiPainter(_confettiController.value),
                    size: Size(
                      MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// CONFETI
// ─────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Random _random = Random(42);

  _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      AppColors.button,
      Colors.amber,
      Colors.green,
      Colors.pink,
      Colors.purple,
      AppColors.accent,
    ];

    for (int i = 0; i < 60; i++) {
      final x = _random.nextDouble() * size.width;
      final startY = -20.0;
      final endY = size.height * 1.1;
      final y = startY + (endY - startY) * progress;
      final wobble = sin(progress * pi * 3 + i) * 15;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final color = colors[i % colors.length].withValues(alpha: opacity);
      final paint = Paint()..color = color;

      if (i % 2 == 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x + wobble, y - i * 10),
              width: 8,
              height: 8,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset(x + wobble, y - i * 10), 4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────
// ENCABEZADO
// ─────────────────────────────────────────────
class _HistoryHeader extends StatelessWidget {
  final int count;
  final double totalSaved;
  final String sortBy;
  final void Function(String) onSortChanged;

  const _HistoryHeader({
    required this.count,
    required this.totalSaved,
    required this.sortBy,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber.shade700,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count meta${count != 1 ? 's' : ''} completada${count != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.amber.shade800,
                        ),
                      ),
                      Text(
                        '¡Eso es disciplina real!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${totalSaved.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                    ),
                    Text(
                      'ahorrado',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Ordenar por:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'Más reciente',
                selected: sortBy == 'reciente',
                onTap: () => onSortChanged('reciente'),
              ),
              const SizedBox(width: 6),
              _SortChip(
                label: 'Mayor monto',
                selected: sortBy == 'monto',
                onTap: () => onSortChanged('monto'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.button.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.button.withValues(alpha: 0.4)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? AppColors.button : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TARJETA DE META COMPLETADA
// ─────────────────────────────────────────────
class _CompletedGoalCard extends StatefulWidget {
  final Goal goal;
  final int index;

  const _CompletedGoalCard({required this.goal, required this.index});

  @override
  State<_CompletedGoalCard> createState() => _CompletedGoalCardState();
}

class _CompletedGoalCardState extends State<_CompletedGoalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _expanded = false;

  Color get _accentColor {
    final amount = widget.goal.targetAmount;
    if (amount >= 500) return const Color(0xFFFFB300);
    if (amount >= 100) return AppColors.button;
    return Colors.green.shade600;
  }

  Color get _accentLight {
    final amount = widget.goal.targetAmount;
    if (amount >= 500) return const Color(0xFFFFF8E1);
    if (amount >= 100) return const Color(0xFFE8F0FE);
    return Colors.green.shade50;
  }

  Color get _accentBorder {
    final amount = widget.goal.targetAmount;
    if (amount >= 500) return Colors.amber.shade200;
    if (amount >= 100) return AppColors.button.withValues(alpha: 0.2);
    return Colors.green.shade200;
  }

  String get _medalLabel {
    final amount = widget.goal.targetAmount;
    if (amount >= 500) return '🥇';
    if (amount >= 100) return '🥈';
    return '🥉';
  }

  String _timeTaken() {
    final periods = widget.goal.periodsNeeded;
    final period = widget.goal.period;
    if (periods == 0) return 'Meta rápida';
    if (period == 'semanal') {
      if (periods == 1) return '1 semana';
      if (periods < 4) return '$periods semanas';
      final months = (periods / 4).round();
      return '$months ${months == 1 ? 'mes' : 'meses'} aprox.';
    } else {
      if (periods == 1) return '1 mes';
      return '$periods meses';
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 80), () {
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
    final goal = widget.goal;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Franja de color
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Medalla
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _accentLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: _accentBorder, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          _medalLabel,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '\$${goal.targetAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _accentColor,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _accentLight,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _accentBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 11,
                                      color: _accentColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _timeTaken(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _accentColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${goal.levels.length} niveles',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.green.shade200,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Cumplida ✓',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => setState(() => _expanded = !_expanded),
                          child: Text(
                            _expanded ? 'Ocultar' : 'Ver niveles',
                            style: TextStyle(
                              fontSize: 11,
                              color: _accentColor.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Niveles expandibles
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _expanded
                    ? Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _accentLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _accentBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Niveles completados',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 10),
                            _MiniSegmentBar(
                              total: goal.levels.length,
                              color: _accentColor,
                            ),
                            const SizedBox(height: 10),
                            ...goal.levels.asMap().entries.map((e) {
                              final level = e.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: _accentColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _accentColor.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        size: 13,
                                        color: _accentColor,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        level.motivationalName(
                                          goal.levels.length,
                                        ),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '\$${level.amountRequired.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _accentColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini barra completa ──
class _MiniSegmentBar extends StatelessWidget {
  final int total;
  final Color color;

  const _MiniSegmentBar({required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final segments = total.clamp(1, 20);
    return Row(
      children: List.generate(segments, (i) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
// ESTADO VACÍO
// ─────────────────────────────────────────────
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber.shade100, width: 2),
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              size: 52,
              color: Colors.amber.shade300,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aún no has completado\nninguna meta.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¡Sigue ahorrando, pronto aparecerán aquí!',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
