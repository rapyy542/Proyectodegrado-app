import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/goal_service.dart';
import 'models/goal_model.dart';
import 'screens/create_goal_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/chat_screen.dart';
import 'theme/app_theme.dart';

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
      theme: AppTheme.theme,
      home: const AuthGate(),
    );
  }
}

// ─────────────────────────────────────────────
// AUTH GATE
// ─────────────────────────────────────────────
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

// ─────────────────────────────────────────────
// LOGIN PAGE
// ─────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
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
    return Scaffold(
      backgroundColor: AppColors.base,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono con gradiente
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.button, AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.button.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.savings,
                      color: AppColors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Savings App',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Alcanza tus metas financieras,\nsin complicaciones.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.75),
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 56),
                  // ── "Para iniciar:" con flecha ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Para iniciar:',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_downward_rounded,
                        color: AppColors.white.withValues(alpha: 0.4),
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('Continuar con Google'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.button,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        shadowColor: AppColors.button.withValues(alpha: 0.4),
                        elevation: 8,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () async {
                        final credential =
                            await AuthService().signInWithGoogle();
                        if (credential != null) {
                          await UserService().createUserIfNotExists(
                            credential.user!,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MAIN SHELL
// ─────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // OPTIMIZACIÓN: las pantallas se construyen lazy (solo cuando se visitan).
  // Antes todas se creaban al arrancar la app aunque no se vieran.
  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const GoalsScreen();
      case 2:
        return const HistoryScreen();
      case 3:
        return const ChatScreen();
      default:
        return const DashboardScreen();
    }
  }

  final List<String> _titles = [
    'Inicio',
    'Mis Metas',
    'Historial',
    'Asistente',
  ];

  void _showProfileSheet(BuildContext context) {
    final user = AuthService().currentUser!;
    // OPTIMIZACIÓN: una sola instancia de GoalService, no una nueva en cada rebuild
    final goalService = GoalService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: StreamBuilder<List<Goal>>(
          stream: goalService.goalsStream(user.uid),
          builder: (context, snapshot) {
            final allGoals = snapshot.data ?? [];
            final completedGoals = allGoals.where((g) => g.completed).toList();
            final totalSaved = allGoals.fold<double>(
              0,
              (sum, g) => sum + g.savedAmount,
            );
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
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Avatar con borde gradiente
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.button, AppColors.accent],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundImage: user.photoURL != null
                          ? NetworkImage(user.photoURL!)
                          : null,
                      backgroundColor: AppColors.background,
                      child: user.photoURL == null
                          ? Text(
                              user.displayName?.substring(0, 1).toUpperCase() ??
                                  'U',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName ?? 'Usuario',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
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
                  Row(
                    children: [
                      _ProfileStat(
                        icon: Icons.savings,
                        label: 'Total ahorrado',
                        value: '\$${totalSaved.toStringAsFixed(0)}',
                        color: AppColors.primary,
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
                        color: AppColors.button,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
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
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showProfileSheet(context),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.button, AppColors.accent],
                  ),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 17,
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  backgroundColor: AppColors.base,
                  child: user.photoURL == null
                      ? Text(
                          user.displayName?.substring(0, 1).toUpperCase() ??
                              'U',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
      // ── Transición entre pantallas: slide + fade ──
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        // OPTIMIZACIÓN: KeyedSubtree fuerza a AnimatedSwitcher a tratar
        // cada pantalla como widget único, evitando redibujos innecesarios
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _buildScreen(_currentIndex),
        ),
      ),
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

// ─────────────────────────────────────────────
// PROFILE STAT WIDGET
// ─────────────────────────────────────────────
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
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
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

// ─────────────────────────────────────────────
// GOALS SCREEN
// ─────────────────────────────────────────────
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  // OPTIMIZACIÓN: instancia única, no una nueva en cada rebuild del StreamBuilder
  final _goalService = GoalService();

  void _goToCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      // ── Botón flotante "Nueva Meta" ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _goToCreate(context),
        backgroundColor: AppColors.button,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: const Text(
          'Nueva Meta',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      body: StreamBuilder<List<Goal>>(
        stream: _goalService.goalsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Ordenar por urgencia: alta → media → baja
          const urgencyOrder = <String, int>{'alta': 0, 'media': 1, 'baja': 2};
          final goals = (snapshot.data ?? [])
              .where((g) => !g.completed)
              .toList()
            ..sort((a, b) => (urgencyOrder[a.urgency] ?? 1)
                .compareTo(urgencyOrder[b.urgency] ?? 1));

          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.button.withValues(alpha: 0.15),
                          AppColors.accent.withValues(alpha: 0.15),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.savings_outlined,
                      size: 60,
                      color: AppColors.button,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Aún no tienes metas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca el botón de abajo para\ncrear tu primera meta de ahorro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: goals.length,
            // OPTIMIZACIÓN: evita mantener vivos widgets fuera de pantalla
            addAutomaticKeepAlives: false,
            itemBuilder: (context, index) {
              // OPTIMIZACIÓN: RepaintBoundary aísla cada card para que cuando
              // una se anime no fuerce a redibujar a las demás
              return RepaintBoundary(
                child: GoalCard(
                  goal: goals[index],
                  uid: user.uid,
                  index: index,
                  goalService: _goalService,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// GOAL CARD con animación de entrada
// ─────────────────────────────────────────────
class GoalCard extends StatefulWidget {
  final Goal goal;
  final String uid;
  final int index;
  // OPTIMIZACIÓN: recibe la instancia en vez de crear GoalService() aquí dentro
  final GoalService goalService;

  const GoalCard({
    super.key,
    required this.goal,
    required this.uid,
    required this.index,
    required this.goalService,
  });

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard> {
  bool _expanded = false;

  Future<void> _handleCompleteLevel() async {
    final nextIndex = widget.goal.levels.indexWhere((l) => !l.completed);
    if (nextIndex == -1) return;

    await widget.goalService.completeNextLevel(
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

  void _showRevertDialog() {
    final lastCompleted = widget.goal.levels.lastIndexWhere((l) => l.completed);
    if (lastCompleted == -1) return;

    final frases = [
      'Los tropiezos son parte del camino. Lo importante es seguir.',
      'Está bien dar un paso atrás para tomar impulso.',
      'No te rindas, cada nivel que retomas te hace más fuerte.',
      'Los grandes logros nacen de la perseverancia.',
      'Hoy retrocedes un paso, mañana avanzas diez.',
    ];
    final frase = frases[DateTime.now().second % frases.length];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange.shade200, width: 2),
                ),
                child: Icon(Icons.undo_rounded,
                    color: Colors.orange.shade600, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Retroceder un nivel?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Esto deshará el nivel ${lastCompleted + 1} completado y reducirá tu ahorro registrado.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.soft.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.format_quote,
                        color: AppColors.button.withValues(alpha: 0.5),
                        size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        frase,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('No'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.undo_rounded, size: 16),
                      label: const Text('Sí, retroceder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await widget.goalService.revertLastLevel(
                          widget.uid,
                          widget.goal.id,
                          widget.goal,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CompletionDialog(
        goalTitle: widget.goal.title,
        onAccept: () async {
          Navigator.of(ctx).pop();
          await widget.goalService.archiveGoal(widget.uid, widget.goal.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final progress = goal.progressPercent;

    // Animación de entrada escalonada según el índice de la tarjeta
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (widget.index * 80)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: child,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.soft.withValues(alpha: 0.25),
            ),
          ),
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
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(goal.urgency),
                      backgroundColor: goal.urgency == 'alta'
                          ? Colors.red[100]
                          : goal.urgency == 'media'
                              ? Colors.orange[100]
                              : AppColors.background,
                      labelStyle: TextStyle(
                        color: goal.urgency == 'alta'
                            ? Colors.red[700]
                            : goal.urgency == 'media'
                                ? Colors.orange[700]
                                : AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (goal.estimatedDate.isNotEmpty)
                  Text(
                    'Para: ${goal.estimatedDate} · ${goal.periodsNeeded} ${goal.period == 'semanal' ? 'semanas' : 'meses'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${goal.savedAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'de \$${goal.targetAmount.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress / 100),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 75
                            ? Colors.green
                            : progress >= 40
                                ? AppColors.button
                                : AppColors.soft,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${progress.toStringAsFixed(0)}% completado',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 14),
                _AnimatedButton(
                  label: 'Completar nivel ${goal.currentLevel + 1}',
                  onPressed: _handleCompleteLevel,
                ),
                if (goal.levels.any((l) => l.completed)) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showRevertDialog,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.undo_rounded,
                            size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          'Retroceder nivel',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _LevelsCompactView(
                  goal: goal,
                  expanded: _expanded,
                  onToggle: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// VISTA COMPACTA DE NIVELES
// ─────────────────────────────────────────────
class _LevelsCompactView extends StatelessWidget {
  final Goal goal;
  final bool expanded;
  final VoidCallback onToggle;

  const _LevelsCompactView({
    required this.goal,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final levels = goal.levels;
    final total = levels.length;
    final completedCount = levels.where((l) => l.completed).length;
    final currentIndex = levels.indexWhere((l) => !l.completed);

    final List<int> visibleIndices = [];
    for (int i = (currentIndex - 2).clamp(0, total - 1);
        i <= (currentIndex + 2).clamp(0, total - 1);
        i++) {
      visibleIndices.add(i);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.layers_rounded,
                    size: 14, color: AppColors.button.withValues(alpha: 0.7)),
                const SizedBox(width: 5),
                Text(
                  '$completedCount de $total niveles',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: onToggle,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.button.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.button.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Text(
                      expanded ? 'Ocultar' : 'Ver niveles',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.button,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 14,
                      color: AppColors.button,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SegmentBar(total: total, completed: completedCount),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: expanded
              ? SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: visibleIndices.length,
                    addAutomaticKeepAlives: false,
                    itemBuilder: (context, i) {
                      final idx = visibleIndices[i];
                      final level = levels[idx];
                      final isCurrent = idx == currentIndex;
                      return _LevelChip(
                        level: level,
                        levelNumber: idx + 1,
                        isCurrent: isCurrent,
                        totalLevels: total,
                      );
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SegmentBar extends StatelessWidget {
  final int total;
  final int completed;

  const _SegmentBar({required this.total, required this.completed});

  @override
  Widget build(BuildContext context) {
    final segments = total.clamp(1, 20);
    final completedSegments =
        ((completed / total) * segments).round().clamp(0, segments);

    return Row(
      children: List.generate(segments, (i) {
        final isDone = i < completedSegments;
        final isCurrent = i == completedSegments;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isDone
                  ? AppColors.button
                  : isCurrent
                      ? AppColors.button.withValues(alpha: 0.35)
                      : Colors.grey.shade200,
              boxShadow: isDone
                  ? [
                      BoxShadow(
                        color: AppColors.button.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final dynamic level;
  final int levelNumber;
  final bool isCurrent;
  final int totalLevels;

  const _LevelChip({
    required this.level,
    required this.levelNumber,
    required this.isCurrent,
    required this.totalLevels,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = level.completed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCurrent ? 110 : 90,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: isCurrent
            ? const LinearGradient(
                colors: [AppColors.button, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isCurrent
            ? null
            : isDone
                ? Colors.green.shade50
                : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? Colors.transparent
              : isDone
                  ? Colors.green.shade200
                  : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.button.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                isDone
                    ? Icons.check_circle_rounded
                    : isCurrent
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                size: 14,
                color: isCurrent
                    ? AppColors.white
                    : isDone
                        ? Colors.green.shade600
                        : Colors.grey.shade400,
              ),
              const SizedBox(width: 4),
              Text(
                'Niv. $levelNumber',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isCurrent
                      ? AppColors.white
                      : isDone
                          ? Colors.green.shade700
                          : Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '\$${level.amountRequired.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isCurrent
                  ? AppColors.white
                  : isDone
                      ? Colors.green.shade800
                      : Colors.grey.shade600,
            ),
          ),
          if (isCurrent)
            Text(
              'Actual',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.white.withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOTÓN ANIMADO
// ─────────────────────────────────────────────
class _AnimatedButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _AnimatedButton({required this.label, required this.onPressed});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.93,
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
        widget.onPressed();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _controller,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.button, AppColors.primary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.button.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check, color: AppColors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DIÁLOGO DE META COMPLETADA
// ─────────────────────────────────────────────
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.amber, Colors.orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: AppColors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¡Meta completada!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
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
                'Lograste tu objetivo. Eso es disciplina real.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onAccept,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
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
