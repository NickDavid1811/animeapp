import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animeapp/feature/home/presentation/widgets/home_tab.dart';
import 'package:animeapp/feature/anime_list/presentation/screens/anime_list_screen.dart';
import 'package:animeapp/feature/anime_list/presentation/screens/favorites_screen.dart';
import 'package:animeapp/feature/anime_list/presentation/provider/anime_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Lista de vistas asociadas a cada pestaña
    final List<Widget> screens = [
      HomeTab(
        onExploreTap: () {
          setState(() {
            _currentIndex = 1;
          });
        },
        onFavoritesTap: () {
          setState(() {
            _currentIndex = 2;
          });
        },
        onGenreTap: (genreLabel, genreQuery, genreId) {
          context.read<AnimeProvider>().filterByGenre(
            label: genreLabel,
            query: genreQuery,
            genreId: genreId,
          );
          setState(() {
            _currentIndex = 1;
          });
        },
      ),
      const AnimeListScreen(),
      const FavoritesScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop/Web layout
        if (constraints.maxWidth >= 600) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: Text('Inicio'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.explore_outlined),
                      selectedIcon: Icon(Icons.explore_rounded),
                      label: Text('Explorar'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite_outline_rounded),
                      selectedIcon: Icon(Icons.favorite_rounded),
                      label: Text('Favoritos'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: screens,
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile layout
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: 'Explorar',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_outline_rounded),
                selectedIcon: Icon(Icons.favorite_rounded),
                label: 'Favoritos',
              ),
            ],
          ),
        );
      },
    );
  }
}

