import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_constants.dart';
import '../models/active_filters.dart';

class FilterModal extends StatefulWidget {
  final bool visible;
  final VoidCallback onClose;
  final Function(ActiveFilters) onApply;
  final ActiveFilters initialFilters;
  final List<String> categorie;

  const FilterModal({
    Key? key,
    required this.visible,
    required this.onClose,
    required this.onApply,
    required this.initialFilters,
    required this.categorie,
  }) : super(key: key);

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late ActiveFilters _currentFilters;

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.initialFilters;
  }

  @override
  void didUpdateWidget(FilterModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilters != widget.initialFilters) {
      _currentFilters = widget.initialFilters;
    }
  }

  void _toggleCategory(String category) {
    setState(() {
      final currentCategories = List<String>.from(_currentFilters.categoria);
      if (currentCategories.contains(category)) {
        currentCategories.remove(category);
      } else {
        currentCategories.add(category);
      }
      _currentFilters = _currentFilters.copyWith(categoria: currentCategories);
    });
  }

  void _clearAllFilters() {
    setState(() {
      _currentFilters = ActiveFilters(categoria: []);
    });
  }

  void _applyFilters() {
    widget.onApply(_currentFilters);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxHeight: 600, minWidth: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppConstants.blueNcs.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filtri',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: AppConstants.gray800,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Icon(
                          Icons.close,
                          color: AppConstants.gray600,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Contenuto
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sezione Categorie
                        Text(
                          'Categorie',
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            //color: AppConstants.gray800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        if (widget.categorie.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Nessuna categoria disponibile',
                              style: GoogleFonts.lato(textStyle: AppConstants.bodyLarge),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.categorie.map((category) {
                              final isSelected = _currentFilters.categoria.contains(category);
                              return GestureDetector(
                                onTap: () => _toggleCategory(category),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                      ? AppConstants.blueNcs 
                                      : AppConstants.gray200,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected 
                                        ? AppConstants.blueNcs 
                                        : AppConstants.gray400,
                                    ),
                                  ),
                                  child: Text(
                                    category,
                                    style: GoogleFonts.lato(textStyle:
                                      TextStyle(
                                        fontSize: 14,
                                        color: isSelected 
                                          ? Colors.white 
                                          : AppConstants.gray700,
                                        fontWeight: isSelected 
                                          ? FontWeight.w600 
                                          : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Footer con pulsanti
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppConstants.gray200.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _clearAllFilters,
                          child: Text(
                            'Cancella tutto',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppConstants.gray600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.blueNcs,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Applica (${_currentFilters.totalCount})',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}