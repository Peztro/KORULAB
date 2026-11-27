import 'package:flutter/material.dart';
import '../servicios/estadisticas_progreso.dart';
import '../tema/tema_korulab.dart';
import '../widgets/ui_koru.dart';

class RewardShopPage extends StatefulWidget {
  static const int hintPrice = 25;
  static const int streakProtectorPrice = 100;
  static const int starMultiplierPrice = 75;
  static const int secondChancePrice = 40;

  final String username;

  const RewardShopPage({super.key, required this.username});

  @override
  State<RewardShopPage> createState() => _RewardShopPageState();
}

class _RewardShopPageState extends State<RewardShopPage> {
  @override
  void initState() {
    super.initState();
    progressStats.loadCourseProgress(widget.username);
  }

  void _showPurchaseResult(bool purchased, String itemName) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            purchased
                ? '$itemName añadido a tu inventario.'
                : 'No tienes suficientes ekostrellas.',
          ),
        ),
      );
  }

  List<_ShopProduct> _products(BuildContext context) {
    final koru = context.koru;
    return [
      _ShopProduct(
        icon: Icons.lightbulb_rounded,
        color: koru.oro,
        title: 'Pista',
        description: 'Descarta una opción incorrecta en quizzes y frases.',
        price: RewardShopPage.hintPrice,
        owned: progressStats.hintCredits,
        onPurchase: () => _showPurchaseResult(progressStats.buyHint(), 'Pista'),
      ),
      _ShopProduct(
        icon: Icons.auto_awesome_rounded,
        color: koru.agua,
        title: 'Doble de ekostrellas',
        description: 'Duplica las estrellas de tu próxima actividad.',
        price: RewardShopPage.starMultiplierPrice,
        owned: progressStats.starMultipliers,
        onPurchase: () => _showPurchaseResult(
          progressStats.buyStarMultiplier(),
          'Doble de ekostrellas',
        ),
      ),
      _ShopProduct(
        icon: Icons.replay_rounded,
        color: koru.hoja,
        title: 'Segundo intento',
        description: 'Vuelve a elegir tras una respuesta incorrecta.',
        price: RewardShopPage.secondChancePrice,
        owned: progressStats.secondChances,
        onPurchase: () => _showPurchaseResult(
          progressStats.buySecondChance(),
          'Segundo intento',
        ),
      ),
      _ShopProduct(
        icon: Icons.shield_rounded,
        color: koru.fuego,
        title: 'Protector de racha',
        description: 'Cuida tu racha un día que no completes lecciones.',
        price: RewardShopPage.streakProtectorPrice,
        owned: progressStats.streakProtectors,
        onPurchase: () => _showPurchaseResult(
          progressStats.buyStreakProtector(),
          'Protector de racha',
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tienda'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tienda'),
              Tab(text: 'Inventario'),
            ],
          ),
        ),
        body: AnimatedBuilder(
          animation: progressStats,
          builder: (context, _) {
            if (!progressStats.isCourseProgressLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            final products = _products(context);
            return TabBarView(
              children: [
                _buildShopTab(context, products),
                _buildInventoryTab(context, products),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildShopTab(BuildContext context, List<_ShopProduct> products) {
    final theme = Theme.of(context);
    final koru = context.koru;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: koru.degradadoHero,
            borderRadius: BorderRadius.circular(KoruRadius.xl),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 34,
                  color: Color(0xFFFFD66B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${progressStats.ekostrellas}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: koru.textoHero,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'ekostrellas para canjear',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: koru.textoHero.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const SectionTitle('Ayudas'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 250,
          ),
          itemBuilder: (context, index) =>
              _ProductCard(product: products[index]),
        ),
      ],
    );
  }

  Widget _buildInventoryTab(BuildContext context, List<_ShopProduct> products) {
    final theme = Theme.of(context);
    final owned = products.where((p) => p.owned > 0).toList();
    if (owned.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTile(
                icon: Icons.inventory_2_rounded,
                color: context.koru.hoja,
                size: 72,
              ),
              const SizedBox(height: 16),
              Text(
                'Tu inventario está vacío',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Canjea ayudas en la tienda con tus ekostrellas.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final product in owned)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FeatureCard(
              title: product.title,
              subtitle: product.description,
              icon: product.icon,
              color: product.color,
              onTap: () {},
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: product.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'x${product.owned}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: product.color,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final _ShopProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAfford = progressStats.ekostrellas >= product.price;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile(icon: product.icon, color: product.color, size: 46),
                const Spacer(),
                if (product.owned > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Tienes ${product.owned}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              product.title,
              style: theme.textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                product.description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canAfford ? product.onPurchase : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 18),
                    const SizedBox(width: 4),
                    Text('${product.price}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopProduct {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final int price;
  final int owned;
  final VoidCallback onPurchase;

  const _ShopProduct({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.price,
    required this.owned,
    required this.onPurchase,
  });
}
