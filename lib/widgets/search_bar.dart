import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_constants.dart';

class SearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final String? initialQuery;

  const SearchBar({
    Key? key,
    required this.onSearch,
    this.initialQuery,
  }) : super(key: key);

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _controller.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _handleSearch() {
    final query = _controller.text.trim();
    // Cancella il debounce se attivo
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Esegui ricerca immediata (senza aspettare il timer)
    if (query.length >= 3 || query.isEmpty) {
      widget.onSearch(query);
    }
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearch('');
  }

  void _onSearchChanged(String value) {
    // Cancella il timer precedente
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Avvia un nuovo timer
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = value.trim();
      // Esegui ricerca solo se almeno 3 caratteri o vuoto (per clear)
      if (query.length >= 3 || query.isEmpty) {
        widget.onSearch(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppConstants.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _handleSearch(),
              onChanged: (value) {
                // Forza rebuild per mostrare/nascondere il pulsante X
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Cerca normative...',
                hintStyle: GoogleFonts.lato(textStyle: AppConstants.cardSubtitle),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: AppConstants.gray800,
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.clear,
                  color: AppConstants.gray400,
                  size: 20,
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.all(4),
            child: ElevatedButton(
              onPressed: _handleSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.blueNcs,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
                shape: const CircleBorder(),
                minimumSize: const Size(44, 44),
              ),
              child: const Icon(
                Icons.search,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}