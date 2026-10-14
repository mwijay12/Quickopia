import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/catalog_provider.dart';
import '../screens/customer/ai_shopping_assistant_sheet.dart';
import '../theme/app_theme.dart';

class CatalogSearchBar extends StatefulWidget {
  const CatalogSearchBar({super.key});

  @override
  State<CatalogSearchBar> createState() => _CatalogSearchBarState();
}

class _CatalogSearchBarState extends State<CatalogSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  void _onChanged(String value) {
    setState(() {}); // updates suffix clear icon
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<CatalogProvider>().search(value);
      }
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {});
    _debounce?.cancel();
    context.read<CatalogProvider>().search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      decoration: InputDecoration(
        hintText: 'Search for anything the store sells...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: _clearSearch,
              )
            : IconButton(
                icon: const Icon(Icons.mic_none_rounded, color: AppTheme.primaryOrange),
                tooltip: 'Voice Search / AI Assistant',
                onPressed: () => AiShoppingAssistantSheet.show(context),
              ),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
