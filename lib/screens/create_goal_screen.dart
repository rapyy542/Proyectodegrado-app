import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/goal_service.dart';

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

  // Resultado del cálculo
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Meta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '¿Qué quieres lograr?',
                  hintText: 'Ej: Comprar una laptop',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Escribe un nombre' : null,
              ),
              const SizedBox(height: 16),

              // Monto objetivo
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto objetivo (\$)',
                  hintText: 'Ej: 1200',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _calculate(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa un monto';
                  if (double.tryParse(v) == null) return 'Monto inválido';
                  if (double.parse(v) <= 0)
                    return 'El monto debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Frecuencia
              const Text(
                'Frecuencia de ahorro',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['semanal', 'mensual'].map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(p),
                      selected: _period == p,
                      onSelected: (_) {
                        setState(() => _period = p);
                        _calculate();
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Capacidad de ahorro
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cuánto puedes ahorrar por $_period (\$)',
                  hintText: 'Ej: 50',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => _calculate(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa tu capacidad';
                  if (double.tryParse(v) == null) return 'Monto inválido';
                  if (double.parse(v) <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Urgencia
              const Text(
                'Urgencia',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['baja', 'media', 'alta'].map((u) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(u),
                      selected: _urgency == u,
                      onSelected: (_) => setState(() => _urgency = u),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Cálculo automático
              if (_showCalculation) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getCalculationColor(),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getCalculationBorderColor()),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getCalculationIcon(),
                            color: _getCalculationBorderColor(),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Proyección de tu meta',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getCalculationBorderColor(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Llegarás a tu meta en $_periodsNeeded $_periodLabel',
                        style: const TextStyle(fontSize: 15),
                      ),
                      Text(
                        'Fecha estimada: $_estimatedDate',
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getAdvice(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Botón crear
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _createGoal,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Crear Meta',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Color del cuadro según urgencia y tiempo
  Color _getCalculationColor() {
    if (_periodsNeeded > 52 && _period == 'semanal') return Colors.red[50]!;
    if (_periodsNeeded > 12 && _period == 'mensual') return Colors.orange[50]!;
    return Colors.green[50]!;
  }

  Color _getCalculationBorderColor() {
    if (_periodsNeeded > 52 && _period == 'semanal') return Colors.red;
    if (_periodsNeeded > 12 && _period == 'mensual') return Colors.orange;
    return Colors.green;
  }

  IconData _getCalculationIcon() {
    if (_periodsNeeded > 52 && _period == 'semanal') return Icons.warning;
    if (_periodsNeeded > 12 && _period == 'mensual') return Icons.info;
    return Icons.check_circle;
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
}
