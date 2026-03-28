import 'screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/goal_service.dart';
import 'models/goal_model.dart';
import 'screens/create_goal_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Savings App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) return const MainShell();
        return const LoginPage();
      },
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Savings App',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Iniciar sesión con Google'),
              onPressed: () async {
                final credential = await AuthService().signInWithGoogle();
                if (credential != null) {
                  await UserService().createUserIfNotExists(credential.user!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    GoalsScreen(),
    HistoryScreen(),
    ChatScreen(),
  ];

  final List<String> _titles = [
    'Inicio',
    'Mis Metas',
    'Historial',
    'Asistente',
  ];

  void _showProfileSheet(BuildContext context) {
    final user = AuthService().currentUser!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StreamBuilder<List<Goal>>(
        stream: GoalService().goalsStream(user.uid),
        builder: (context, snapshot) {
          final allGoals = snapshot.data ?? [];
          final completedGoals = allGoals.where((g) => g.completed).toList();
          final totalSaved = allGoals.fold<double>(
            0,
            (sum, g) => sum + g.savedAmount,
          );

          // Fecha de creación del usuario
          final createdAt = user.metadata.creationTime;
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
          final joinDate = createdAt != null
              ? '${createdAt.day} de ${months[createdAt.month - 1]} de ${createdAt.year}'
              : 'Desconocido';

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Foto y nombre
                CircleAvatar(
                  radius: 44,
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  backgroundColor: Colors.green[100],
                  child: user.photoURL == null
                      ? Text(
                          user.displayName?.substring(0, 1).toUpperCase() ??
                              'U',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user.displayName ?? 'Usuario',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? '',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Miembro desde $joinDate',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
                const SizedBox(height: 24),

                // Estadísticas
                Row(
                  children: [
                    _ProfileStat(
                      icon: Icons.savings,
                      label: 'Total ahorrado',
                      value: '\$${totalSaved.toStringAsFixed(0)}',
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _ProfileStat(
                      icon: Icons.emoji_events,
                      label: 'Metas cumplidas',
                      value: '${completedGoals.length}',
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 12),
                    _ProfileStat(
                      icon: Icons.flag,
                      label: 'Metas activas',
                      value: '${allGoals.where((g) => !g.completed).length}',
                      color: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Botón cerrar sesión
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await AuthService().signOut();
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

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          // Burbuja de perfil
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showProfileSheet(context),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                backgroundColor: Colors.green[200],
                child: user.photoURL == null
                    ? Text(
                        user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Mis Metas',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Asistente',
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ProfileStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser!;

    return StreamBuilder<List<Goal>>(
      stream: GoalService().goalsStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final goals = (snapshot.data ?? []).where((g) => !g.completed).toList();

        if (goals.isEmpty) {
          return const Center(
            child: Text(
              'No tienes metas activas.\n¡Crea una!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: goals.length,
          itemBuilder: (context, index) {
            return GoalCard(goal: goals[index], uid: user.uid);
          },
        );
      },
    );
  }
}

class GoalCard extends StatefulWidget {
  final Goal goal;
  final String uid;

  const GoalCard({super.key, required this.goal, required this.uid});

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard> {
  bool _expanded = false;

  Future<void> _handleCompleteLevel() async {
    final nextIndex = widget.goal.levels.indexWhere((l) => !l.completed);
    if (nextIndex == -1) return;

    await GoalService().completeNextLevel(
      widget.uid,
      widget.goal.id,
      widget.goal,
    );

    final newSaved =
        widget.goal.savedAmount + widget.goal.levels[nextIndex].amountRequired;

    if (newSaved >= widget.goal.targetAmount && mounted) {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CompletionDialog(
        goalTitle: widget.goal.title,
        onAccept: () async {
          Navigator.of(ctx).pop();
          await GoalService().archiveGoal(widget.uid, widget.goal.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final progress = goal.progressPercent;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(goal.urgency),
                  backgroundColor: goal.urgency == 'alta'
                      ? Colors.red[100]
                      : goal.urgency == 'media'
                      ? Colors.orange[100]
                      : Colors.green[100],
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (goal.estimatedDate.isNotEmpty)
              Text(
                'Para: ${goal.estimatedDate} · ${goal.periodsNeeded} ${goal.period == 'semanal' ? 'semanas' : 'meses'}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            const SizedBox(height: 8),
            Text(
              '\$${goal.savedAmount.toStringAsFixed(0)} de \$${goal.targetAmount.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Text(
              '${progress.toStringAsFixed(0)}% completado',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 16),
              label: Text('Completar nivel ${goal.currentLevel + 1}'),
              onPressed: _handleCompleteLevel,
            ),
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'Ocultar niveles' : 'Ver niveles'),
            ),
            if (_expanded)
              ...goal.levels.map(
                (level) => ListTile(
                  dense: true,
                  leading: Icon(
                    level.completed ? Icons.lock_open : Icons.lock,
                    color: level.completed ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  title: Text(level.motivationalName(goal.levels.length)),
                  subtitle: Text(
                    '\$${level.amountRequired.toStringAsFixed(0)} · ${level.completed ? '✅ Completado' : '🔒 Pendiente'}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompletionDialog extends StatefulWidget {
  final String goalTitle;
  final VoidCallback onAccept;

  const _CompletionDialog({required this.goalTitle, required this.onAccept});

  @override
  State<_CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<_CompletionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              const Text(
                '¡Meta completada!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '"${widget.goalTitle}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¡Lograste tu objetivo! Eso es disciplina real 💪',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '¡Genial! Cerrar',
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
}


// error en pubsec-yaml por el http de la IA groqqq aahjhjawurbqobiuqooiqoi