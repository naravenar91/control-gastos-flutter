import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/gasto_bloc.dart';
import '../bloc/gasto_state.dart';
import '../widgets/add_gasto_sheet.dart';
import 'categorias_page.dart';
import 'charts_page.dart';
import 'export_page.dart';
import 'home_page.dart';
import 'settings_page.dart';
import '../../core/constants/app_strings.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const HomePage(),
    const ChartsPage(),
    const CategoriasPage(),
    const ExportPage(),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        physics: const NeverScrollableScrollPhysics(), // Deshabilitar swipe para usar solo navbar
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.red.shade700,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: AppStrings.navGastos,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: AppStrings.navGraficos,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: AppStrings.navCategorias,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_upload),
            label: AppStrings.navExportar,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: AppStrings.navAjustes,
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? BlocBuilder<GastoBloc, GastoState>(
              builder: (context, state) {
                return FloatingActionButton.extended(
                  onPressed: () {
                    final currentMonth = (state is GastoLoaded) ? state.selectedMonth : DateTime.now();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => AddGastoSheet(selectedMonth: currentMonth),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text(AppStrings.nuevoRegistro),
                  backgroundColor: Colors.green,
                );
              },
            )
          : null,
    );
  }
}
