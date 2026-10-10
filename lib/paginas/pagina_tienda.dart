import 'package:flutter/material.dart';
import '../servicios/estadisticas_progreso.dart';

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
  final _pageController = PageController(viewportFraction: 0.82);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    progressStats.loadCourseProgress(widget.username);
  }

  void _showPurchaseResult(bool purchased, String itemName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          purchased
              ? '$itemName añadido a tu inventario.'
              : 'No tienes suficientes ekostrellas.',
        ),
      ),
    );
  }

  Widget _buildProductCard({
    required IconData icon,
    required String title,
    required String description,
    required int price,
    required int owned,
    required VoidCallback onPurchase,
  }) {
    final theme = Theme.of(context);
    final canAfford = progressStats.ekostrellas >= price;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.65),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.18),
                  child: Icon(icon, color: theme.colorScheme.primaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Text('Tienes $owned'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canAfford ? onPurchase : null,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text('Canjear por $price ekostrellas'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('Tienda de recompensas'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.storefront_outlined), text: 'Tienda'),
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Inventario'),
            ],
          ),
        ),
        body: AnimatedBuilder(
          animation: progressStats,
          builder: (context, _) {
            if (!progressStats.isCourseProgressLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            final products = <_ShopProduct>[
              _ShopProduct(
                icon: Icons.lightbulb_outline,
                title: 'Pista para una pregunta',
                description:
                    'Elimina una opción incorrecta en quizzes y actividades de completar.',
                price: RewardShopPage.hintPrice,
                owned: progressStats.hintCredits,
                onPurchase: () =>
                    _showPurchaseResult(progressStats.buyHint(), 'Pista'),
              ),
              _ShopProduct(
                icon: Icons.stars_outlined,
                title: 'Doble de ekostrellas',
                description:
                    'Duplica las ekostrellas de la próxima actividad que completes.',
                price: RewardShopPage.starMultiplierPrice,
                owned: progressStats.starMultipliers,
                onPurchase: () => _showPurchaseResult(
                  progressStats.buyStarMultiplier(),
                  'Doble de ekostrellas',
                ),
              ),
              _ShopProduct(
                icon: Icons.replay,
                title: 'Segundo intento',
                description:
                    'Después de una respuesta incorrecta, permite elegir de nuevo en quizzes y ejercicios de completar.',
                price: RewardShopPage.secondChancePrice,
                owned: progressStats.secondChances,
                onPurchase: () => _showPurchaseResult(
                  progressStats.buySecondChance(),
                  'Segundo intento',
                ),
              ),
              _ShopProduct(
                icon: Icons.shield_outlined,
                title: 'Protector de racha',
                description:
                    'Se activa automáticamente por cada día que no completes una lección.',
                price: RewardShopPage.streakProtectorPrice,
                owned: progressStats.streakProtectors,
                onPurchase: () => _showPurchaseResult(
                  progressStats.buyStreakProtector(),
                  'Protector de racha',
                ),
              ),
            ];
            return TabBarView(
              children: [
                _buildShopTab(theme, products),
                _buildInventoryTab(theme, products),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildShopTab(ThemeData theme, List<_ShopProduct> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${progressStats.ekostrellas} ekostrellas',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Desliza para ver los productos y canjea tus estrellas por ayudas.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 330,
          child: PageView.builder(
            controller: _pageController,
            itemBuilder: (context, index) {
              final product = products[index % products.length];
              return _buildProductCard(
                icon: product.icon,
                title: product.title,
                description: product.description,
                price: product.price,
                owned: product.owned,
                onPurchase: product.onPurchase,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryTab(ThemeData theme, List<_ShopProduct> products) {
    final owned = products.where((p) => p.owned > 0).toList();
    if (owned.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aún no tienes habilidades. Canjéalas en la tienda con tus ekostrellas.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final product in owned)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.18),
                child: Icon(
                  product.icon,
                  color: theme.colorScheme.primaryContainer,
                ),
              ),
              title: Text(
                product.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(product.description),
              trailing: Text(
                '${product.owned}\n${product.owned == 1 ? 'unidad' : 'unidades'}',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge,
              ),
            ),
          ),
      ],
    );
  }
}

class _ShopProduct {
  final IconData icon;
  final String title;
  final String description;
  final int price;
  final int owned;
  final VoidCallback onPurchase;

  const _ShopProduct({
    required this.icon,
    required this.title,
    required this.description,
    required this.price,
    required this.owned,
    required this.onPurchase,
  });
}
