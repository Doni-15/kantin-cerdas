import 'package:flutter/material.dart';

class M05SearchFilterSheet extends StatefulWidget {
  const M05SearchFilterSheet({super.key});

  @override
  State createState() => _M05SearchFilterSheetState();
}

class _M05SearchFilterSheetState extends State {
  String _selectedCategory = 'Semua';
  double _maxPrice = 20000; // 1 Titik Batas Harga Maksimal
  String _selectedWaitingTime = '10 menit';

  final List _categories = ['Semua', 'Nasi', 'Mi', 'Minuman', 'Camilan'];
  final List _waitingTimes = ['5 menit', '10 menit', '15 menit', '20 menit', 'Tanpa batas'];

  void _resetFilter() {
    setState(() {
      _selectedCategory = 'Semua';
      _maxPrice = 50000;
      _selectedWaitingTime = 'Tanpa batas';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Sheet
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter menu', // Judul sesuai instruksi
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Kategori (Dipertahankan)
          Text(
            'Kategori',
            style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: colorScheme.primaryContainer.withValues(alpha: 0.4),
                    side: BorderSide(
                      color: isSelected ? colorScheme.primary : Colors.transparent,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Batas Harga Maksimal (1 Titik Slider)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Batas harga',
                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              Text(
                'Maks. Rp${_maxPrice.round()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: _maxPrice,
            min: 5000,
            max: 50000,
            divisions: 9,
            activeColor: colorScheme.primary,
            label: 'Rp${_maxPrice.round()}',
            onChanged: (value) {
              setState(() {
                _maxPrice = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // 3. Waktu Tunggu (5, 10, 15, 20 menit, Tanpa batas)
          Text(
            'Waktu tunggu',
            style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _waitingTimes.map((time) {
              final isSelected = _selectedWaitingTime == time;
              return ChoiceChip(
                label: Text(time),
                selected: isSelected,
                selectedColor: colorScheme.primaryContainer.withValues(alpha: 0.4),
                side: BorderSide(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedWaitingTime = time;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // 4. Tombol Utama & Reset Filter
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary, // Warna Oranye
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Tampilkan menu', // Sesuai permintaan
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _resetFilter,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
              ),
              child: const Text(
                'Reset filter', // Sesuai permintaan
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}