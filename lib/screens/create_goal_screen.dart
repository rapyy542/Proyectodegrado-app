import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/goal_service.dart';
import '../theme/app_theme.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _capacityController = TextEditingController();

  String _period = 'semanal';
  String _urgency = 'media';
  bool _loading = false;

  int _periodsNeeded = 0;
  String _estimatedDate = '';
  bool _showCalculation = false;

  void _calculate() {
    final target = double.tryParse(_targetController.text);
    final capacity = double.tryParse(_capacityController.text);

    if (target == null || capacity == null || capacity <= 0) {
      setState(() => _showCalculation = false);
      return;
    }

    final periods = (target / capacity).ceil();
    final now = DateTime.now();
    DateTime estimated;

    if (_period == 'semanal') {
      estimated = now.add(Duration(days: periods * 7));
    } else {
      estimated = DateTime(now.year, now.month + periods, now.day);
    }

    final months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    setState(() {
      _periodsNeeded = periods;
      _estimatedDate = '${months[estimated.month - 1]} ${estimated.year}';
      _showCalculation = true;
    });
  }

  String get _periodLabel => _period == 'semanal' ? 'semanas' : 'meses';

  Color _getCalcColor() {
    if (_periodsNeeded > 52 && _period == 'semanal') {
      return Colors.orange.shade50;
    }
    if (_periodsNeeded > 12 && _period == 'mensual') {
      return Colors.orange.shade50;
    }
    return Colors.green.shade50;
  }

  Color _getCalcBorderColor() {
    if (_periodsNeeded > 52 && _period == 'semanal') {
      return Colors.orange.shade200;
    }
    if (_periodsNeeded > 12 && _period == 'mensual') {
      return Colors.orange.shade200;
    }
    return Colors.green.shade200;
  }

  Color _getCalcIconColor() {
    if (_periodsNeeded > 52 && _period == 'semanal') {
      return Colors.orange.shade600;
    }
    if (_periodsNeeded > 12 && _period == 'mensual') {
      return Colors.orange.shade600;
    }
    return Colors.green.shade600;
  }

  IconData _getCalcIcon() {
    if (_periodsNeeded > 52 && _period == 'semanal') return Icons.info_outline;
    if (_periodsNeeded > 12 && _period == 'mensual') return Icons.info_outline;
    return Icons.check_circle_outline;
  }

  String _getAdvice() {
    if (_period == 'semanal' && _periodsNeeded > 52) {
      return 'Tu meta tomará más de un año. Considera aumentar tu ahorro semanal para llegar más rápido.';
    }
    if (_period == 'semanal' && _periodsNeeded > 26) {
      return 'Va a tomar varios meses. Es alcanzable si mantienes la constancia.';
    }
    if (_period == 'mensual' && _periodsNeeded > 12) {
      return 'Tu meta tomará más de un año. Subir un poco tu ahorro mensual haría gran diferencia.';
    }
    if (_periodsNeeded <= 4) {
      return '¡Excelente! Meta muy alcanzable a corto plazo. 🎯';
    }
    return 'Meta alcanzable. ¡Mantén la constancia y llegarás!';
  }

  Future<void> _createGoal() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await GoalService().createGoal(
        uid,
        title: _titleController.text.trim(),
        targetAmount: double.parse(_targetController.text),
        savingCapacity: double.parse(_capacityController.text),
        period: _period,
        urgency: _urgency,
        estimatedDate: _estimatedDate,
        periodsNeeded: _periodsNeeded,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Meta')),
      backgroundColor: const Color(0xFFF5F8FF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Intro suave ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.soft.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.button.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Completa los datos y calcularemos cuánto tiempo te tomará.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Sección: Nombre ──
              _SectionLabel(
                label: '¿Qué quieres lograr?',
                icon: Icons.flag_outlined,
              ),
              const SizedBox(height: 8),
              _SoftField(
                controller: _titleController,
                hint: 'Ej: Comprar una laptop',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Escribe un nombre' : null,
              ),
              const SizedBox(height: 20),

              // ── Sección: Monto ──
              _SectionLabel(label: 'Monto objetivo', icon: Icons.attach_money),
              const SizedBox(height: 8),
              _SoftField(
                controller: _targetController,
                hint: 'Ej: 1200',
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculate(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa un monto';
                  if (double.tryParse(v) == null) return 'Monto inválido';
                  if (double.parse(v) <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Sección: Frecuencia ──
              _SectionLabel(
                label: 'Frecuencia de ahorro',
                icon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 10),
              Row(
                children: ['semanal', 'mensual'].map((p) {
                  final selected = _period == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _SoftChip(
                      label: p,
                      selected: selected,
                      onTap: () {
                        setState(() => _period = p);
                        _calculate();
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Sección: Capacidad ──
              _SectionLabel(
                label: 'Cuánto puedes ahorrar por $_period',
                icon: Icons.savings_outlined,
              ),
              const SizedBox(height: 8),
              _SoftField(
                controller: _capacityController,
                hint: 'Ej: 50',
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculate(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa tu capacidad';
                  if (double.tryParse(v) == null) return 'Monto inválido';
                  if (double.parse(v) <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Sección: Urgencia ──
              _SectionLabel(label: 'Urgencia', icon: Icons.speed_outlined),
              const SizedBox(height: 10),
              Row(
                children: [
                  _UrgencyChip(
                    label: 'baja',
                    selected: _urgency == 'baja',
                    color: Colors.green,
                    onTap: () => setState(() => _urgency = 'baja'),
                  ),
                  const SizedBox(width: 10),
                  _UrgencyChip(
                    label: 'media',
                    selected: _urgency == 'media',
                    color: Colors.orange,
                    onTap: () => setState(() => _urgency = 'media'),
                  ),
                  const SizedBox(width: 10),
                  _UrgencyChip(
                    label: 'alta',
                    selected: _urgency == 'alta',
                    color: Colors.red,
                    onTap: () => setState(() => _urgency = 'alta'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Proyección animada ──
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                child: _showCalculation
                    ? Column(
                        children: [
                          _ProjectionCard(
                            periodsNeeded: _periodsNeeded,
                            periodLabel: _periodLabel,
                            estimatedDate: _estimatedDate,
                            advice: _getAdvice(),
                            bgColor: _getCalcColor(),
                            borderColor: _getCalcBorderColor(),
                            iconColor: _getCalcIconColor(),
                            icon: _getCalcIcon(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              // ── Botón crear ──
              _CreateButton(loading: _loading, onPressed: _createGoal),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ETIQUETA DE SECCIÓN
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.button),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// CAMPO DE TEXTO SUAVE
// ─────────────────────────────────────────────
class _SoftField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  const _SoftField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: AppColors.darkText),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.button.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade200),
        ),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CHIP SUAVE PARA FRECUENCIA
// ─────────────────────────────────────────────
class _SoftChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SoftChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.button.withValues(alpha: 0.1)
              : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.button.withValues(alpha: 0.4)
                : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? AppColors.button : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CHIP DE URGENCIA con color propio
// ─────────────────────────────────────────────
class _UrgencyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _UrgencyChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.4)
                : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? color : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TARJETA DE PROYECCIÓN
// ─────────────────────────────────────────────
class _ProjectionCard extends StatelessWidget {
  final int periodsNeeded;
  final String periodLabel;
  final String estimatedDate;
  final String advice;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;
  final IconData icon;

  const _ProjectionCard({
    required this.periodsNeeded,
    required this.periodLabel,
    required this.estimatedDate,
    required this.advice,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Proyección de tu meta',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Info en chips suaves
          Row(
            children: [
              _InfoPill(
                icon: Icons.timer_outlined,
                text: '$periodsNeeded $periodLabel',
                color: iconColor,
              ),
              const SizedBox(width: 8),
              _InfoPill(
                icon: Icons.calendar_month_outlined,
                text: estimatedDate,
                color: iconColor,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Consejo
          Text(
            advice,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOTÓN CREAR con efecto de escala
// ─────────────────────────────────────────────
class _CreateButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onPressed;

  const _CreateButton({required this.loading, required this.onPressed});

  @override
  State<_CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<_CreateButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        if (!widget.loading) widget.onPressed();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _controller,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.loading
                ? LinearGradient(
                    colors: [
                      AppColors.soft.withValues(alpha: 0.5),
                      AppColors.soft.withValues(alpha: 0.3),
                    ],
                  )
                : const LinearGradient(
                    colors: [AppColors.button, AppColors.primary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.loading
                ? []
                : [
                    BoxShadow(
                      color: AppColors.button.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Crear Meta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
