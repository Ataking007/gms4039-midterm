import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() => runApp(const TartPieApp());

// ---------------------------------------------------------------------------
// Colors
// ---------------------------------------------------------------------------
const kBrown = Color(0xFF4A2C1D);
const kCream = Color(0xFFFFF4E2);
const kBerry = Color(0xFFB8324F);
const kGold = Color(0xFFF2B33D);
const kSage = Color(0xFF7A9A6B);
const kWood = Color(0xFF9C6A3C);
const kOven = Color(0xFFD9622B);

int bestScore = 0;

// Bake meter: 0 = raw dough, 1.0 = end of golden zone, maxBake = burnt.
const double maxBake = 1.3;
const double rawLimit = 0.55;
const double goldenStart = 0.8;

String bakeQuality(double b) {
  if (b < rawLimit) return 'Underbaked';
  if (b < goldenStart) return 'Well baked';
  if (b <= 1.0) return 'Golden';
  return 'Burnt';
}

// ---------------------------------------------------------------------------
// Data: ingredients, pies, drinks, customers
// ---------------------------------------------------------------------------
enum Part { crust, filling, topping }

class Ingredient {
  final String id;
  final String name;
  final String emoji;
  final Part part;
  final Color color;
  const Ingredient(this.id, this.name, this.emoji, this.part, this.color);
}

const List<Ingredient> ingredients = [
  Ingredient('short', 'Shortcrust', '🥧', Part.crust, Color(0xFFE2B86E)),
  Ingredient('graham', 'Graham Crust', '🍪', Part.crust, Color(0xFF9A6236)),
  Ingredient('apple', 'Apple', '🍎', Part.filling, Color(0xFFEBCB7A)),
  Ingredient('cherry', 'Cherry', '🍒', Part.filling, Color(0xFFA8152E)),
  Ingredient('blueberry', 'Blueberry', '🫐', Part.filling, Color(0xFF3B3A8C)),
  Ingredient('strawberry', 'Strawberry', '🍓', Part.filling, Color(0xFFE23B4E)),
  Ingredient('lemon', 'Lemon Curd', '🍋', Part.filling, Color(0xFFF6DA4A)),
  Ingredient('pumpkin', 'Pumpkin', '🎃', Part.filling, Color(0xFFD9772B)),
  Ingredient('choco', 'Chocolate', '🍫', Part.filling, Color(0xFF4E2A1A)),
  Ingredient('pecan', 'Pecan', '🌰', Part.filling, Color(0xFF8A4F24)),
  Ingredient('custard', 'Custard', '🍮', Part.filling, Color(0xFFF7E3A1)),
  Ingredient('lattice', 'Lattice Top', '🥨', Part.topping, Color(0xFFE2B86E)),
  Ingredient('meringue', 'Meringue', '☁️', Part.topping, Color(0xFFFFFBF2)),
  Ingredient('cream', 'Whipped Cream', '🍦', Part.topping, Color(0xFFFFFFFF)),
];

final Map<String, Ingredient> byId = {for (final i in ingredients) i.id: i};

/// Ingredients of a recipe in menu order (crust, fillings, toppings).
List<Ingredient> ingredientsOf(Set<String> ids) =>
    ingredients.where((i) => ids.contains(i.id)).toList();

class Pie {
  final String name;
  final int price;
  final Set<String> recipe;
  const Pie(this.name, this.price, this.recipe);
}

const List<Pie> pies = [
  Pie('Apple Pie', 14, {'short', 'apple', 'lattice'}),
  Pie('Cherry Pie', 14, {'short', 'cherry', 'lattice'}),
  Pie('Blueberry Pie', 15, {'short', 'blueberry', 'lattice'}),
  Pie('Pecan Pie', 15, {'short', 'pecan'}),
  Pie('Custard Tart', 12, {'short', 'custard'}),
  Pie('Chocolate Tart', 13, {'short', 'choco'}),
  Pie('Pumpkin Pie', 16, {'short', 'pumpkin', 'cream'}),
  Pie('Lemon Meringue Pie', 18, {'short', 'lemon', 'meringue'}),
  Pie('Strawberry Tart', 17, {'short', 'custard', 'strawberry'}),
  Pie('Lemon Cream Tart', 16, {'graham', 'lemon', 'cream'}),
  Pie('Chocolate Cream Pie', 18, {'graham', 'choco', 'cream'}),
  Pie('Mixed Berry Pie', 20,
      {'short', 'cherry', 'blueberry', 'strawberry', 'lattice'}),
];

class Drink {
  final String name;
  final String emoji;
  final int price;
  const Drink(this.name, this.emoji, this.price);
}

const List<Drink> drinks = [
  Drink('Black Tea', '🫖', 4),
  Drink('Coffee', '☕', 5),
  Drink('Green Tea', '🍵', 4),
  Drink('Cold Milk', '🥛', 3),
  Drink('Apple Juice', '🧃', 4),
];

class CustomerType {
  final String emoji;
  final String name;
  const CustomerType(this.emoji, this.name);
}

const List<CustomerType> customerTypes = [
  CustomerType('👵', 'Granny Mabel'),
  CustomerType('👨‍🌾', 'Farmer Tom'),
  CustomerType('👩', 'Lily'),
  CustomerType('🧑‍🎓', 'Noah'),
  CustomerType('👨‍💼', 'Mr. Clark'),
  CustomerType('👩‍🍳', 'Chef Rosa'),
  CustomerType('🧔', 'Oliver'),
  CustomerType('👧', 'Little Mia'),
  CustomerType('👴', 'Grandpa Ben'),
  CustomerType('👩‍🎨', 'Ivy'),
];

class Order {
  final Pie pie;
  final Drink? drink;
  const Order(this.pie, this.drink);
  int get price => pie.price + (drink?.price ?? 0);
}

class Customer {
  final CustomerType type;
  final Order order;
  const Customer(this.type, this.order);
}

// ---------------------------------------------------------------------------
// App
// ---------------------------------------------------------------------------
class TartPieApp extends StatelessWidget {
  const TartPieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tart & Pie House',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kBerry),
      ),
      home: const HomeScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// Home screen
// ---------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _play() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const GameScreen()));
    if (mounted) setState(() {});
  }

  void _howToPlay() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCream,
        title: const Text('How to Play 🥧'),
        content: const SingleChildScrollView(
          child: Text(
            'You are the baker of Tart & Pie House!\n\n'
            '1. A customer comes in and orders a pie or tart.\n'
            '2. Build it: pick ONE crust, then the fillings and the topping '
            '(open 📖 Recipes if you forget).\n'
            '3. Press BAKE, watch the oven meter and press TAKE OUT '
            'in the GOLDEN zone.\n'
            '4. From level 2, customers also order a drink.\n'
            '5. Press SERVE before the customer loses patience.\n\n'
            'POINTS\n'
            '✅ Correct order: + menu price\n'
            '⚡ Speed bonus: up to +10 for fast service\n'
            '✨ Golden bake: +8   ·   Well baked: +3   ·   Underbaked: −3\n'
            '🔥 Combo: 3+ correct in a row = double points\n'
            '❌ Wrong order: −5 points and −3 s patience\n'
            '💀 Burnt pie served: −5 points\n'
            '😠 Customer leaves: −10 points and −1 ❤️\n\n'
            'Every 4 happy customers the level goes up and customers '
            'get less patient.\n'
            'The shift ends after 150 seconds or when you lose all 3 ❤️.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7A3B2E), Color(0xFF3E2016)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(top: 30, left: 24, child: _Deco('🍒', 34, -0.4)),
              const Positioned(
                  top: 120, right: 30, child: _Deco('🥧', 44, 0.3)),
              const Positioned(
                  bottom: 140, left: 30, child: _Deco('🍋', 38, 0.2)),
              const Positioned(
                  bottom: 60, right: 40, child: _Deco('🫐', 32, 0.6)),
              const Positioned(
                  top: 260, left: 60, child: _Deco('🍎', 30, -0.2)),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 170,
                        height: 170,
                        child: PieView(
                            ids: {'short', 'cherry', 'lattice'}, bake: 0.9),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Tart & Pie House',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: kCream,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Bake golden pies for the hungriest town!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: kGold),
                      ),
                      const SizedBox(height: 36),
                      SizedBox(
                        width: 230,
                        height: 54,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: kGold,
                            foregroundColor: kBrown,
                          ),
                          onPressed: _play,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Open the Bakery',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: 230,
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kCream,
                            side: const BorderSide(color: kGold),
                          ),
                          onPressed: _howToPlay,
                          icon: const Icon(Icons.help_outline),
                          label: const Text('How to Play'),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        '🏆 Best score: $bestScore',
                        style: const TextStyle(color: kCream, fontSize: 16),
                      ),
                    ],
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

class _Deco extends StatelessWidget {
  final String emoji;
  final double size;
  final double angle;
  const _Deco(this.emoji, this.size, this.angle);

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: angle,
        child: Opacity(
          opacity: 0.35,
          child: Text(emoji, style: TextStyle(fontSize: size)),
        ),
      );
}

// ---------------------------------------------------------------------------
// Game screen
// ---------------------------------------------------------------------------
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const double shiftLength = 150;
  static const double bakeSpeed = 0.1 / 3.5; // golden end after 3.5 s

  final _rng = Random();
  Timer? _timer;
  bool _ended = false;

  int score = 0;
  int hearts = 3;
  int streak = 0;
  int bestStreak = 0;
  int served = 0;
  int goldenPies = 0;
  double timeLeft = shiftLength;

  late Customer customer;
  double patience = 1;
  double maxPatience = 1;

  // The tray
  final Set<String> pie = {};
  Drink? cup;
  double bake = 0;
  bool baking = false;
  bool baked = false;

  String? toast;
  Color toastColor = Colors.green;
  int _toastId = 0;
  String? reaction;

  int get level => 1 + served ~/ 4;

  String get mood {
    if (reaction != null) return reaction!;
    final f = patience / maxPatience;
    if (f > 0.6) return '🙂';
    if (f > 0.3) return '😐';
    return '😠';
  }

  @override
  void initState() {
    super.initState();
    _newCustomer();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted || _ended) return;
    setState(() {
      timeLeft -= 0.1;
      patience -= 0.1;
      if (baking) {
        bake += bakeSpeed;
        if (bake >= maxBake) {
          bake = maxBake;
          baking = false;
          baked = true;
          _showToast('Burnt! 💀 Trash it and bake a new one', Colors.red);
        }
      }
      if (patience <= 0) _customerLeft();
    });
    if (timeLeft <= 0 || hearts <= 0) _endGame();
  }

  void _resetTray() {
    pie.clear();
    cup = null;
    bake = 0;
    baking = false;
    baked = false;
  }

  void _newCustomer() {
    final type = customerTypes[_rng.nextInt(customerTypes.length)];
    final p = pies[_rng.nextInt(pies.length)];
    Drink? d;
    if (level >= 2 && _rng.nextBool()) {
      d = drinks[_rng.nextInt(drinks.length)];
    }
    customer = Customer(type, Order(p, d));
    maxPatience = max(14.0, 26.0 - level * 1.5) + (d != null ? 4 : 0);
    patience = maxPatience;
    _resetTray();
  }

  void _showToast(String text, Color color) {
    toast = text;
    toastColor = color;
    final id = ++_toastId;
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted && id == _toastId) {
        setState(() {
          toast = null;
          reaction = null;
        });
      }
    });
  }

  void _customerLeft() {
    hearts--;
    streak = 0;
    score = max(0, score - 10);
    reaction = null;
    _showToast('${customer.type.name} left angry!  −10  −1 ❤️', Colors.red);
    if (hearts > 0) _newCustomer();
  }

  void _toggleIngredient(Ingredient i) {
    setState(() {
      if (baking) {
        _showToast('The pie is in the oven! 🔥', Colors.orange);
        return;
      }
      if (baked) {
        _showToast('Already baked! Serve it or trash it.', Colors.orange);
        return;
      }
      if (pie.contains(i.id)) {
        pie.remove(i.id);
        return;
      }
      if (i.part == Part.crust) {
        pie.removeWhere((id) => byId[id]!.part == Part.crust);
      } else if (!pie.any((id) => byId[id]!.part == Part.crust)) {
        _showToast('Start with a crust first! 🥧', Colors.orange);
        return;
      }
      pie.add(i.id);
    });
  }

  void _pickDrink(Drink d) {
    setState(() => cup = cup == d ? null : d);
  }

  void _clearTray() {
    setState(_resetTray);
  }

  void _bakeButton() {
    setState(() {
      if (baking) {
        baking = false;
        baked = true;
        final q = bakeQuality(bake);
        _showToast(
          q == 'Golden' ? 'Perfect golden crust! ✨' : '$q pie',
          q == 'Golden' ? Colors.green.shade700 : Colors.orange,
        );
      } else if (baked) {
        _showToast('Already baked! Serve it or trash it.', Colors.orange);
      } else if (!pie.any((id) => byId[id]!.part == Part.crust)) {
        _showToast('Add a crust first! 🥧', Colors.orange);
      } else {
        bake = 0;
        baking = true;
      }
    });
  }

  void _serve() {
    if (pie.isEmpty && cup == null) {
      setState(() => _showToast('Your tray is empty!', Colors.orange));
      return;
    }
    if (pie.isNotEmpty && !baked) {
      setState(() => _showToast(
          baking ? 'Take the pie out of the oven first!' : 'Bake the pie first! 🔥',
          Colors.orange));
      return;
    }
    final o = customer.order;

    setState(() {
      if (baked && bake > 1.0) {
        streak = 0;
        score = max(0, score - 5);
        patience -= 3;
        _resetTray();
        reaction = '🤢';
        _showToast('A burnt pie?! −5', Colors.red);
        return;
      }

      final pieOk = setEquals(pie, o.pie.recipe);
      final drinkOk = cup == o.drink;

      if (pieOk && drinkOk) {
        streak++;
        bestStreak = max(bestStreak, streak);
        served++;
        final q = bakeQuality(bake);
        final bakeBonus = q == 'Golden' ? 8 : (q == 'Well baked' ? 3 : -3);
        if (q == 'Golden') goldenPies++;
        final speed = (patience / maxPatience * 10).round();
        final mult = streak >= 3 ? 2 : 1;
        final gained = max(1, (o.price + speed + bakeBonus) * mult);
        score += gained;
        reaction = q == 'Golden' ? '😍' : '😋';
        final b = bakeBonus >= 0 ? '+$bakeBonus' : '$bakeBonus';
        _showToast(
          '+$gained  (order ${o.price} · speed +$speed · bake $b'
          '${mult > 1 ? ' · ×2 🔥' : ''})',
          Colors.green.shade700,
        );
        _newCustomer();
      } else {
        streak = 0;
        score = max(0, score - 5);
        patience -= 3;
        _resetTray();
        reaction = '😤';
        _showToast(
            pieOk ? 'Wrong drink!  −5' : 'That is not what I ordered!  −5',
            Colors.red);
      }
    });
  }

  void _endGame() {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();
    final isNewBest = score > bestScore;
    if (isNewBest) bestScore = score;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameOverScreen(
          score: score,
          served: served,
          goldenPies: goldenPies,
          bestStreak: bestStreak,
          newBest: isNewBest,
          outOfHearts: hearts <= 0,
        ),
      ),
    );
  }

  void _openRecipes() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCream,
      showDragHandle: true,
      builder: (_) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const Text('📖 Recipe Book',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Every pie must be baked to a golden crust!',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          for (final p in pies)
            ListTile(
              leading: SizedBox(
                  width: 48,
                  height: 48,
                  child: PieView(ids: p.recipe, bake: 0.9)),
              title: Text('${p.name}  ·  ${p.price} pts'),
              subtitle: Text(ingredientsOf(p.recipe)
                  .map((i) => '${i.emoji} ${i.name}')
                  .join('  +  ')),
            ),
          const SizedBox(height: 8),
          const Text('Drinks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          for (final d in drinks)
            ListTile(
              leading: Text(d.emoji, style: const TextStyle(fontSize: 30)),
              title: Text('${d.name}  ·  ${d.price} pts'),
            ),
        ],
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E2016),
      body: SafeArea(
        child: Column(
          children: [
            _hud(),
            Expanded(flex: 5, child: _scene()),
            Expanded(flex: 7, child: _counter()),
          ],
        ),
      ),
    );
  }

  Widget _hud() {
    Widget chip(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(60),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(text,
              style: const TextStyle(
                  color: kCream, fontWeight: FontWeight.bold, fontSize: 14)),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          chip('⭐ $score'),
          chip('⏱ ${max(0, timeLeft.ceil())}s'),
          chip('❤️' * max(0, hearts) + '🤍' * (3 - max(0, hearts))),
          chip(streak >= 3 ? 'Lv $level 🔥' : 'Lv $level'),
        ],
      ),
    );
  }

  Widget _scene() {
    final o = customer.order;
    final f = (patience / maxPatience).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        return Stack(
          children: [
            Positioned.fill(
                child: CustomPaint(painter: BakeryPainter(baking))),
            // chalkboard menu
            Positioned(
              top: h * 0.12,
              right: w * 0.03,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F3B33),
                  border: Border.all(color: kWood, width: 4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TART & PIE HOUSE\nbaked fresh daily 🥧',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white70, fontSize: 11, height: 1.3),
                ),
              ),
            ),
            // shelf with pies
            Positioned(
              top: h * 0.42 - 28,
              left: w * 0.64,
              child: const Text('🥧 🍰 🍯 🥧',
                  style: TextStyle(fontSize: 20)),
            ),
            // oven label
            Positioned(
              top: h * 0.62 + 4,
              left: w * 0.04,
              width: w * 0.3,
              child: Text(
                baking ? 'OVEN 🔥 ${(bake * 100).round()}%' : 'OVEN',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: kCream,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
            // customer + speech bubble
            Positioned(
              left: w * 0.37,
              right: 8,
              bottom: 6,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6)
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("I'd like…",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Row(children: [
                            SizedBox(
                                width: 38,
                                height: 38,
                                child: PieView(ids: o.pie.recipe, bake: 0.9)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(o.pie.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                            ),
                          ]),
                          if (o.drink != null)
                            Row(children: [
                              Text(o.drink!.emoji,
                                  style: const TextStyle(fontSize: 26)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text('+ ${o.drink!.name}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                              ),
                            ]),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: f,
                              minHeight: 7,
                              backgroundColor: Colors.black12,
                              color: f > 0.6
                                  ? Colors.green
                                  : (f > 0.3 ? Colors.orange : Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(mood, style: const TextStyle(fontSize: 24)),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(customer.type.emoji,
                            key: ValueKey(customer),
                            style: const TextStyle(fontSize: 64)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: kCream,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(customer.type.name,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // toast
            if (toast != null)
              Positioned(
                top: 8,
                left: 16,
                right: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: toastColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(toast!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String get _bakeStatus {
    if (baking) return 'Baking… ${(bake * 100).round()}%';
    if (!baked) return pie.isEmpty ? 'Empty dish' : 'Raw dough';
    final q = bakeQuality(bake);
    if (q == 'Golden') return 'Golden ✨';
    if (q == 'Burnt') return 'Burnt 💀';
    return q;
  }

  String get _bakeButtonLabel {
    if (baking) return 'TAKE OUT 🧤';
    if (baked) return 'BAKED ✓';
    return 'BAKE 🔥';
  }

  Widget _counter() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8A5A33), Color(0xFF5E3B22)],
        ),
        border: Border(top: BorderSide(color: Color(0xFFC08A55), width: 6)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // tray: pie dish + bake meter + drink
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(children: [
                  SizedBox(
                      width: 96,
                      height: 96,
                      child: PieView(ids: pie, bake: bake)),
                  Text(_bakeStatus,
                      style: const TextStyle(
                          color: kCream,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Oven meter',
                        style: TextStyle(color: kCream, fontSize: 12)),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 150,
                      height: 16,
                      child: CustomPaint(painter: BakeMeterPainter(bake)),
                    ),
                    const SizedBox(height: 4),
                    const Text('raw · baked · GOLDEN · burnt',
                        style: TextStyle(color: kCream, fontSize: 10)),
                  ],
                ),
                const SizedBox(width: 16),
                Column(children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: kGold, width: 4),
                    ),
                    child: Text(cup?.emoji ?? '',
                        style: const TextStyle(fontSize: 32)),
                  ),
                  const Text('Drink',
                      style: TextStyle(color: kCream, fontSize: 12)),
                ]),
              ],
            ),
            _section('1 · Crust (pick one)', Part.crust),
            _section('2 · Filling', Part.filling),
            _section('3 · Topping', Part.topping),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 4, top: 8),
              child: Text('Drinks',
                  style: TextStyle(
                      color: kCream,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final d in drinks)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => _pickDrink(d),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: cup == d ? kGold : kCream,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(d.emoji,
                              style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // actions
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _clearTray,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Empty tray',
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  onPressed: _openRecipes,
                  icon: const Icon(Icons.menu_book),
                  tooltip: 'Recipes',
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: kOven,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _bakeButton,
                      child: Text(_bakeButtonLabel,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: kGold,
                        foregroundColor: kBrown,
                      ),
                      onPressed: _serve,
                      child: const Text('SERVE 🛎️',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, Part part) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4, top: 8),
          child: Text(title,
              style: const TextStyle(
                  color: kCream, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final i in ingredients)
              if (i.part == part) _ingredientButton(i),
          ],
        ),
      ],
    );
  }

  Widget _ingredientButton(Ingredient i) {
    final selected = pie.contains(i.id);
    final locked = baking || baked;
    return Opacity(
      opacity: locked && !selected ? 0.5 : 1.0,
      child: InkWell(
        onTap: () => _toggleIngredient(i),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 80,
          height: 60,
          decoration: BoxDecoration(
            color: selected ? kGold : kCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? kBrown : Colors.transparent, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(i.emoji, style: const TextStyle(fontSize: 22)),
              Text(i.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: kBrown)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Game over screen
// ---------------------------------------------------------------------------
class GameOverScreen extends StatelessWidget {
  final int score;
  final int served;
  final int goldenPies;
  final int bestStreak;
  final bool newBest;
  final bool outOfHearts;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.served,
    required this.goldenPies,
    required this.bestStreak,
    required this.newBest,
    required this.outOfHearts,
  });

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 16)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: const Color(0xFF3E2016),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              color: kCream,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(outOfHearts ? '😵' : '🌙',
                    style: const TextStyle(fontSize: 64)),
                Text(
                  outOfHearts ? 'Too many angry customers!' : 'Bakery closed!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (newBest)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('🏆 New best score!',
                        style: TextStyle(
                            color: kBerry,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(height: 16),
                stat('⭐ Score', '$score'),
                stat('🥧 Customers served', '$served'),
                stat('✨ Golden pies', '$goldenPies'),
                stat('🔥 Best combo', '$bestStreak'),
                stat('🏆 Best score', '$bestScore'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: kBerry, foregroundColor: kCream),
                    onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const GameScreen())),
                    child: const Text('Play Again'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Back to Menu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Visuals: pie, oven meter, bakery background
// ---------------------------------------------------------------------------
class PieView extends StatelessWidget {
  final Set<String> ids;
  final double bake;
  const PieView({super.key, required this.ids, this.bake = 0.9});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: PiePainter(ids, bake));
}

Color crustColor(String type, double bake) {
  final raw =
      type == 'graham' ? const Color(0xFFB98A5E) : const Color(0xFFF1DAAB);
  final golden =
      type == 'graham' ? const Color(0xFF8A5530) : const Color(0xFFD99A45);
  const burnt = Color(0xFF3B2418);
  if (bake <= 1.0) return Color.lerp(raw, golden, bake.clamp(0.0, 1.0))!;
  final t = ((bake - 1.0) / (maxBake - 1.0)).clamp(0.0, 1.0);
  return Color.lerp(golden, burnt, t)!;
}

const List<String> fillingPriority = [
  'choco',
  'pumpkin',
  'lemon',
  'custard',
  'pecan',
  'apple',
  'cherry',
  'blueberry',
  'strawberry',
];

class PiePainter extends CustomPainter {
  final Set<String> ids;
  final double bake;
  PiePainter(Set<String> ids, this.bake) : ids = Set<String>.of(ids);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final rr = min(size.width, size.height) / 2 * 0.95;
    Offset at(double angle, double dist) =>
        c + Offset(cos(angle), sin(angle)) * dist;

    // pie dish
    canvas.drawCircle(c, rr, Paint()..color = const Color(0xFFB7C2CC));
    canvas.drawCircle(
      c,
      rr,
      Paint()
        ..color = const Color(0xFF7D8B97)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, rr * 0.05),
    );

    String? crustId;
    if (ids.contains('graham')) crustId = 'graham';
    if (ids.contains('short')) crustId = 'short';
    if (crustId == null) {
      canvas.drawCircle(c, rr * 0.8, Paint()..color = const Color(0xFFD3DBE2));
      return;
    }

    final crust = crustColor(crustId, bake);
    final crustDark = Color.lerp(crust, Colors.black, 0.25)!;

    // fluted crust edge
    final crustPaint = Paint()..color = crust;
    for (var k = 0; k < 18; k++) {
      canvas.drawCircle(at(2 * pi * k / 18, rr * 0.8), rr * 0.12, crustPaint);
    }
    canvas.drawCircle(c, rr * 0.84, crustPaint);
    canvas.drawCircle(c, rr * 0.7, Paint()..color = crustDark);

    // filling base
    String? base;
    for (final f in fillingPriority) {
      if (ids.contains(f)) {
        base = f;
        break;
      }
    }
    final fillR = rr * 0.66;
    final fillColor = base == null
        ? Color.lerp(crust, Colors.white, 0.25)!
        : byId[base]!.color;
    canvas.drawCircle(c, fillR, Paint()..color = fillColor);

    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: c, radius: fillR)));

    // fruit & nut details
    if (ids.contains('apple')) {
      final p = Paint()
        ..color = const Color(0xFFFFF3C8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, rr * 0.05);
      for (var k = 0; k < 8; k++) {
        final a = 2 * pi * k / 8;
        canvas.drawArc(Rect.fromCircle(center: at(a, fillR * 0.5), radius: rr * 0.16),
            a, pi * 0.9, false, p);
      }
    }
    if (ids.contains('pecan')) {
      final p = Paint()..color = const Color(0xFF6B3A1A);
      for (var k = 0; k < 14; k++) {
        final ring = k < 9;
        final a = ring ? 2 * pi * k / 9 : 2 * pi * (k - 9) / 5 + 0.4;
        canvas.save();
        canvas.translate(at(a, fillR * (ring ? 0.66 : 0.28)).dx,
            at(a, fillR * (ring ? 0.66 : 0.28)).dy);
        canvas.rotate(a);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset.zero, width: rr * 0.24, height: rr * 0.12),
            p);
        canvas.restore();
      }
    }
    void berries(int ringCount, double ringDist, int innerCount,
        double radius, Color color, double offset) {
      final p = Paint()..color = color;
      final hi = Paint()..color = Colors.white.withAlpha(150);
      for (var k = 0; k < ringCount + innerCount; k++) {
        final ring = k < ringCount;
        final a = ring
            ? 2 * pi * k / ringCount + offset
            : 2 * pi * (k - ringCount) / max(1, innerCount) + offset + 0.5;
        final pos = at(a, fillR * (ring ? ringDist : ringDist * 0.4));
        canvas.drawCircle(pos, radius, p);
        canvas.drawCircle(
            pos + Offset(-radius * 0.35, -radius * 0.35), radius * 0.3, hi);
      }
    }

    if (ids.contains('cherry')) {
      berries(8, 0.6, 4, rr * 0.09, const Color(0xFFD0233F), 0);
    }
    if (ids.contains('blueberry')) {
      berries(10, 0.72, 5, rr * 0.065, const Color(0xFF2E2F7A), 0.3);
    }
    if (ids.contains('strawberry')) {
      final p = Paint()..color = const Color(0xFFE8384F);
      final seed = Paint()..color = const Color(0xFFFFE08A);
      for (var k = 0; k < 8; k++) {
        final a = 2 * pi * k / 8 + 0.2;
        final pos = at(a, fillR * 0.48);
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(a);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset.zero, width: rr * 0.26, height: rr * 0.18),
            p);
        canvas.drawCircle(Offset(rr * 0.04, 0), rr * 0.015, seed);
        canvas.drawCircle(Offset(-rr * 0.04, rr * 0.03), rr * 0.015, seed);
        canvas.restore();
      }
    }

    // toppings
    if (ids.contains('lattice')) {
      final dough = crustColor('short', bake);
      final strip = Paint()..color = dough;
      final edge = Paint()
        ..color = Color.lerp(dough, Colors.black, 0.3)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(0.8, rr * 0.012);
      final sw = rr * 0.13;
      for (var i = -2; i <= 2; i++) {
        final r = Rect.fromCenter(
            center: Offset(c.dx + i * fillR * 0.42, c.dy),
            width: sw,
            height: fillR * 2);
        canvas.drawRect(r, strip);
        canvas.drawRect(r, edge);
      }
      for (var i = -2; i <= 2; i++) {
        final r = Rect.fromCenter(
            center: Offset(c.dx, c.dy + i * fillR * 0.42),
            width: fillR * 2,
            height: sw);
        canvas.drawRect(r, strip);
        canvas.drawRect(r, edge);
      }
    }
    if (ids.contains('meringue')) {
      final white = Paint()..color = const Color(0xFFFFFBF2);
      final tipColor = bake <= 1.0
          ? Color.lerp(const Color(0xFFFFF6E0), const Color(0xFFC98A3A),
              bake.clamp(0.0, 1.0))!
          : Color.lerp(const Color(0xFFC98A3A), const Color(0xFF3B2418),
              ((bake - 1.0) / (maxBake - 1.0)).clamp(0.0, 1.0))!;
      final tip = Paint()..color = tipColor;
      canvas.drawCircle(c, fillR * 0.92, white);
      for (var k = 0; k < 13; k++) {
        final ring = k < 9;
        final a = ring ? 2 * pi * k / 9 : 2 * pi * (k - 9) / 4 + 0.3;
        final pos = at(a, fillR * (ring ? 0.6 : 0.25));
        canvas.drawCircle(pos, rr * 0.17, white);
        canvas.drawCircle(
            pos + Offset(-rr * 0.04, -rr * 0.04), rr * 0.07, tip);
      }
    }
    canvas.restore();

    if (ids.contains('cream')) {
      final white = Paint()..color = Colors.white;
      final line = Paint()
        ..color = const Color(0xFFD8D0C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(0.8, rr * 0.015);
      for (var k = 0; k < 12; k++) {
        final pos = at(2 * pi * k / 12, fillR * 0.82);
        canvas.drawCircle(pos, rr * 0.11, white);
        canvas.drawCircle(pos, rr * 0.11, line);
        canvas.drawCircle(pos, rr * 0.05, line);
      }
      canvas.drawCircle(c, rr * 0.12, white);
      canvas.drawCircle(c, rr * 0.12, line);
    }
  }

  @override
  bool shouldRepaint(covariant PiePainter oldDelegate) =>
      !setEquals(oldDelegate.ids, ids) || oldDelegate.bake != bake;
}

class BakeMeterPainter extends CustomPainter {
  final double value;
  BakeMeterPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final box = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h), Radius.circular(h / 2));
    canvas.save();
    canvas.clipRRect(box);
    void zone(double a, double b, Color color) {
      canvas.drawRect(Rect.fromLTRB(w * a / maxBake, 0, w * b / maxBake, h),
          Paint()..color = color);
    }

    zone(0, rawLimit, const Color(0xFFE6DCCD));
    zone(rawLimit, goldenStart, const Color(0xFFF2C27A));
    zone(goldenStart, 1.0, const Color(0xFFF2A516));
    zone(1.0, maxBake, const Color(0xFF4A2E22));
    canvas.restore();
    canvas.drawRRect(
      box,
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final x = w * (value / maxBake).clamp(0.0, 1.0);
    canvas.drawRect(
        Rect.fromLTWH(x - 2, -3, 4, h + 6), Paint()..color = Colors.white);
    canvas.drawRect(
        Rect.fromLTWH(x - 1, -3, 2, h + 6), Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant BakeMeterPainter oldDelegate) =>
      oldDelegate.value != value;
}

class BakeryPainter extends CustomPainter {
  final bool glow;
  BakeryPainter(this.glow);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // wallpaper
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6DCC8), Color(0xFFE9BFA3)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    final stripe = Paint()..color = Colors.white.withAlpha(45);
    for (double x = 0; x < w; x += 30) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 14, h * 0.62), stripe);
    }

    // wooden lower wall
    canvas.drawRect(Rect.fromLTWH(0, h * 0.62, w, h * 0.38),
        Paint()..color = const Color(0xFF7E4F31));
    final plank = Paint()
      ..color = Colors.black.withAlpha(50)
      ..strokeWidth = 2;
    for (double x = 0; x < w; x += 40) {
      canvas.drawLine(Offset(x, h * 0.62), Offset(x, h), plank);
    }
    canvas.drawRect(
        Rect.fromLTWH(0, h * 0.6, w, h * 0.025), Paint()..color = kWood);

    // bunting
    final string = Paint()
      ..color = const Color(0xFF6B4A35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    double sag(double x) => h * 0.04 + sin(pi * x / w) * h * 0.05;
    final rope = Path()..moveTo(0, sag(0));
    for (double x = 0; x <= w; x += 8) {
      rope.lineTo(x, sag(x));
    }
    canvas.drawPath(rope, string);
    const flagColors = [kBerry, kGold, kSage, Color(0xFF5B8DB8)];
    const n = 12;
    for (var k = 0; k < n; k++) {
      final x = w * (k + 0.5) / n;
      final y = sag(x);
      final flag = Path()
        ..moveTo(x - w * 0.025, y)
        ..lineTo(x + w * 0.025, y)
        ..lineTo(x, y + h * 0.07)
        ..close();
      canvas.drawPath(flag, Paint()..color = flagColors[k % 4]);
    }

    // brick oven
    final oven = Rect.fromLTWH(w * 0.04, h * 0.18, w * 0.3, h * 0.44);
    final ovenShape = RRect.fromRectAndCorners(
      oven,
      topLeft: Radius.circular(oven.width * 0.5),
      topRight: Radius.circular(oven.width * 0.5),
    );
    // chimney
    canvas.drawRect(
        Rect.fromLTWH(oven.center.dx - oven.width * 0.08, 0,
            oven.width * 0.16, oven.top + 10),
        Paint()..color = const Color(0xFF8E3E2C));
    canvas.drawRRect(ovenShape, Paint()..color = const Color(0xFFB5523B));
    canvas.save();
    canvas.clipRRect(ovenShape);
    final mortar = Paint()
      ..color = const Color(0xFFE9C9A8)
      ..strokeWidth = 1.5;
    final rowH = oven.height / 8;
    for (var r = 0; r < 8; r++) {
      final y = oven.top + r * rowH;
      canvas.drawLine(Offset(oven.left, y), Offset(oven.right, y), mortar);
      final shift = r.isEven ? 0.0 : oven.width / 8;
      for (double x = oven.left + shift; x < oven.right; x += oven.width / 4) {
        canvas.drawLine(Offset(x, y), Offset(x, y + rowH), mortar);
      }
    }
    canvas.restore();

    // oven mouth
    final mouth = Rect.fromLTWH(oven.left + oven.width * 0.2,
        oven.top + oven.height * 0.42, oven.width * 0.6, oven.height * 0.5);
    final mouthShape = RRect.fromRectAndCorners(
      mouth,
      topLeft: Radius.circular(mouth.width * 0.5),
      topRight: Radius.circular(mouth.width * 0.5),
    );
    canvas.drawRRect(mouthShape, Paint()..color = const Color(0xFF2A1A14));
    if (glow) {
      canvas.drawRRect(
        mouthShape,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, 0.8),
            radius: 0.9,
            colors: [
              const Color(0xFFFFE27A),
              const Color(0xFFFF8A1F),
              const Color(0xFF2A1A14),
            ],
          ).createShader(mouth),
      );
      final flame = Paint()..color = const Color(0xFFFFC23D);
      for (var k = 0; k < 3; k++) {
        final fx = mouth.left + mouth.width * (0.3 + 0.2 * k);
        final fh = mouth.height * (k == 1 ? 0.55 : 0.4);
        final p = Path()
          ..moveTo(fx - mouth.width * 0.08, mouth.bottom)
          ..quadraticBezierTo(fx - mouth.width * 0.06, mouth.bottom - fh * 0.6,
              fx, mouth.bottom - fh)
          ..quadraticBezierTo(fx + mouth.width * 0.06,
              mouth.bottom - fh * 0.6, fx + mouth.width * 0.08, mouth.bottom)
          ..close();
        canvas.drawPath(p, flame);
      }
    } else {
      final ember = Paint()..color = const Color(0xFFB4441E);
      for (var k = 0; k < 4; k++) {
        canvas.drawCircle(
            Offset(mouth.left + mouth.width * (0.25 + 0.17 * k),
                mouth.bottom - 4),
            3,
            ember);
      }
    }

    // pie shelf
    canvas.drawRect(Rect.fromLTWH(w * 0.62, h * 0.42, w * 0.35, 6),
        Paint()..color = kWood);

    // counter top edge
    canvas.drawRect(Rect.fromLTWH(0, h * 0.95, w, h * 0.05),
        Paint()..color = const Color(0xFFC08A55));
  }

  @override
  bool shouldRepaint(covariant BakeryPainter oldDelegate) =>
      oldDelegate.glow != glow;
}
