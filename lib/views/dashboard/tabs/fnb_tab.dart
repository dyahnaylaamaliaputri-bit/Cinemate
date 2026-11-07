// lib/views/dashboard/tabs/fnb_tab.dart
// Tab Pesan Makanan / F&B: Katalog camilan dan minuman bioskop (PB-011)

import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class FnbTab extends StatelessWidget {
  const FnbTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Menu contoh sesuai data seed supabase_schema.sql
    final dummyFnb = [
      {'name': 'Popcorn Regular', 'category': 'Snack', 'price': 'Rp 35.000', 'desc': 'Popcorn butter ukuran regular'},
      {'name': 'Popcorn Large', 'category': 'Snack', 'price': 'Rp 50.000', 'desc': 'Popcorn butter ukuran besar'},
      {'name': 'Nachos', 'category': 'Snack', 'price': 'Rp 45.000', 'desc': 'Nachos renyah dengan saus keju gurih'},
      {'name': 'Coca-Cola Regular', 'category': 'Drink', 'price': 'Rp 25.000', 'desc': 'Minuman soda segar 400ml'},
      {'name': 'Combo 1', 'category': 'Combo', 'price': 'Rp 55.000', 'desc': 'Popcorn Regular + Coca-Cola Regular'},
      {'name': 'Combo 2', 'category': 'Combo', 'price': 'Rp 95.000', 'desc': 'Popcorn Large + 2 Coca-Cola Regular'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'PESAN MAKANAN & MINUMAN',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 17,
          ),
        ),
      ),
      body: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: dummyFnb.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = dummyFnb[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item['category'] == 'Drink'
                        ? Icons.local_drink_rounded
                        : item['category'] == 'Combo'
                            ? Icons.fastfood_rounded
                            : Icons.lunch_dining_rounded,
                    color: AppColors.gold,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name']!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['desc']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['price']!,
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: const Size(60, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('+ Tambah', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
