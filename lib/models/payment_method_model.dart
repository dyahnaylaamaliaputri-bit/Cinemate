// lib/models/payment_method_model.dart
// Model untuk metode pembayaran simulasi (PB-021)

import 'package:flutter/material.dart';

enum PaymentCategory {
  virtualAccount,
  eWallet,
  qris,
}

class PaymentMethodModel {
  final String id;
  final String name;
  final PaymentCategory category;
  final IconData icon;
  final String description;
  final String? accountNumber;
  final List<String> instructions;

  PaymentMethodModel({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.description,
    this.accountNumber,
    this.instructions = const [],
  });

  static List<PaymentMethodModel> get predefinedMethods => [
        // 1. Virtual Account
        PaymentMethodModel(
          id: 'bca_va',
          name: 'BCA Virtual Account',
          category: PaymentCategory.virtualAccount,
          icon: Icons.account_balance_rounded,
          description: 'Transfer via BCA Mobile, KlikBCA, atau ATM BCA',
          accountNumber: '8277 0812 3456 7890',
          instructions: [
            'Buka aplikasi BCA Mobile / KlikBCA',
            'Pilih menu m-Transfer > BCA Virtual Account',
            'Masukkan nomor Virtual Account di atas',
            'Periksa detail tagihan, lalu masukkan PIN m-BCA Anda',
            'Pembayaran otomatis terverifikasi secara instan',
          ],
        ),
        PaymentMethodModel(
          id: 'mandiri_va',
          name: 'Mandiri Virtual Account',
          category: PaymentCategory.virtualAccount,
          icon: Icons.account_balance_rounded,
          description: 'Transfer via Livin\' by Mandiri atau ATM Mandiri',
          accountNumber: '8870 8812 3456 7890',
          instructions: [
            'Buka aplikasi Livin\' by Mandiri',
            'Pilih menu Bayar > Multipayment / Virtual Account',
            'Masukkan kode perusahaan dan nomor Virtual Account',
            'Konfirmasi jumlah pembayaran dan masukkan PIN',
          ],
        ),
        PaymentMethodModel(
          id: 'bri_va',
          name: 'BRI Virtual Account (BRIVA)',
          category: PaymentCategory.virtualAccount,
          icon: Icons.account_balance_rounded,
          description: 'Transfer via BRImo atau ATM BRI',
          accountNumber: '1280 0812 3456 7890',
          instructions: [
            'Buka aplikasi BRImo',
            'Pilih menu Pembayaran > BRIVA',
            'Masukkan nomor BRIVA di atas',
            'Konfirmasi pembayaran dan masukkan PIN BRImo',
          ],
        ),
        PaymentMethodModel(
          id: 'bni_va',
          name: 'BNI Virtual Account',
          category: PaymentCategory.virtualAccount,
          icon: Icons.account_balance_rounded,
          description: 'Transfer via BNI Mobile Banking atau ATM BNI',
          accountNumber: '9880 0812 3456 7890',
          instructions: [
            'Buka aplikasi BNI Mobile Banking',
            'Pilih menu Transfer > Virtual Account Billing',
            'Masukkan nomor VA di atas',
            'Konfirmasi dan selesaikan transaksi dengan Password Transaksi',
          ],
        ),

        // 2. E-Wallet
        PaymentMethodModel(
          id: 'gopay',
          name: 'GoPay',
          category: PaymentCategory.eWallet,
          icon: Icons.account_balance_wallet_rounded,
          description: 'Bayar instan dengan saldo GoPay atau GoPayLater',
          instructions: [
            'Pastikan nomor HP akun GoPay Anda terdaftar',
            'Klik Bayar Sekarang untuk konfirmasi pembayaran simulasi',
            'Saldo akan otomatis terpotong tanpa biaya admin',
          ],
        ),
        PaymentMethodModel(
          id: 'ovo',
          name: 'OVO',
          category: PaymentCategory.eWallet,
          icon: Icons.wallet_rounded,
          description: 'Notifikasi push akan dikirimkan ke aplikasi OVO Anda',
          instructions: [
            'Masukkan nomor HP akun OVO Anda',
            'Buka notifikasi di aplikasi OVO dalam waktu 60 detik',
            'Selesaikan pembayaran dengan memasukkan Security Code OVO',
          ],
        ),
        PaymentMethodModel(
          id: 'dana',
          name: 'DANA',
          category: PaymentCategory.eWallet,
          icon: Icons.credit_card_rounded,
          description:
              'Bayar cepat dan mudah langsung dari dompet digital DANA',
          instructions: [
            'Hubungkan akun DANA Anda',
            'Konfirmasi jumlah tagihan pemesanan tiket',
            'Masukkan PIN DANA Anda untuk verifikasi instan',
          ],
        ),
        PaymentMethodModel(
          id: 'shopeepay',
          name: 'ShopeePay',
          category: PaymentCategory.eWallet,
          icon: Icons.shopping_bag_rounded,
          description: 'Gunakan saldo ShopeePay atau SPayLater',
          instructions: [
            'Aplikasi akan memproses otorisasi ShopeePay secara otomatis',
            'Konfirmasi pin transaksi untuk menyelesaikan pesanan',
          ],
        ),

        // 3. QRIS
        PaymentMethodModel(
          id: 'qris',
          name: 'QRIS Bersama (Semua Bank & E-Wallet)',
          category: PaymentCategory.qris,
          icon: Icons.qr_code_scanner_rounded,
          description:
              'Scan menggunakan BCA, Livin\', BRImo, GoPay, OVO, DANA, dll.',
          instructions: [
            'Buka aplikasi mobile banking atau dompet digital pilihan Anda',
            'Pilih fitur Scan / Pindai QRIS',
            'Arahkan kamera ke kode QR yang ditampilkan di layar',
            'Periksa nama merchant: CINEMATE INDONESIA',
            'Masukkan PIN Anda dan pembayaran selesai',
          ],
        ),
      ];
}
