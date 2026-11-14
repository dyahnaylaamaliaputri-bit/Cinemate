// lib/views/profile/edit_profile_view.dart
// Halaman form edit profil pengguna: nama, nomor telepon & foto profil kamera/galeri (PB-061, PB-062)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../utils/app_colors.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final AuthController _authCtrl = Get.find<AuthController>();
  final ProfileController _profileCtrl = Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : Get.put(ProfileController());

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  int _selectedAvatarIndex = 0;

  final List<Map<String, dynamic>> _presetAvatars = [
    {
      'label': 'Cinephile',
      'icon': Icons.movie_filter_rounded,
      'color': AppColors.primary,
    },
    {
      'label': 'VIP Gold',
      'icon': Icons.workspace_premium_rounded,
      'color': AppColors.gold,
    },
    {
      'label': 'Director',
      'icon': Icons.videocam_rounded,
      'color': Colors.deepPurpleAccent,
    },
    {
      'label': 'Popcorn Fan',
      'icon': Icons.fastfood_rounded,
      'color': Colors.amber,
    },
    {
      'label': 'Sci-Fi Star',
      'icon': Icons.rocket_launch_rounded,
      'color': Colors.cyanAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    final user = _authCtrl.currentUser.value;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '081234567890');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _showImagePickerModal() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Foto Profil (PB-061)',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt_outlined, color: AppColors.gold),
              title: const Text('Ambil dari Kamera',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () async {
                Get.back();
                await _profileCtrl.pickProfileImage(ImageSource.camera);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.gold),
              title: const Text('Pilih dari Galeri',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () async {
                Get.back();
                await _profileCtrl.pickProfileImage(ImageSource.gallery);
                setState(() {});
              },
            ),
            if (_profileCtrl.avatarPath.value != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.primary),
                title: const Text('Hapus Foto Kustom (Kembali ke Lencana)',
                    style: TextStyle(color: AppColors.primary)),
                onTap: () async {
                  Get.back();
                  await _profileCtrl.removeCustomAvatar();
                  setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    final current = _authCtrl.currentUser.value;
    if (current != null) {
      final updated = current.copyWith(
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        avatarUrl: _profileCtrl.avatarPath.value ?? current.avatarUrl,
      );
      _authCtrl.currentUser.value = updated;
    }

    Get.back();
    Get.snackbar(
      'Profil Diperbarui',
      'Perubahan profil berhasil disimpan ke sesi lokal.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.card,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'EDIT PROFIL',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Selector Badge Avatar & Unggah Foto (PB-061)
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Obx(() {
                          final path = _profileCtrl.avatarPath.value;
                          final hasCustomImage =
                              path != null && File(path).existsSync();

                          if (hasCustomImage) {
                            return CircleAvatar(
                              radius: 48,
                              backgroundColor: AppColors.gold,
                              child: CircleAvatar(
                                radius: 45,
                                backgroundImage: FileImage(File(path)),
                              ),
                            );
                          }

                          return CircleAvatar(
                            radius: 45,
                            backgroundColor:
                                _presetAvatars[_selectedAvatarIndex]['color']
                                    as Color,
                            child: Icon(
                              _presetAvatars[_selectedAvatarIndex]['icon']
                                  as IconData,
                              size: 40,
                              color: Colors.white,
                            ),
                          );
                        }),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImagePickerModal,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _showImagePickerModal,
                      icon: const Icon(Icons.photo_camera_rounded, size: 14),
                      label: const Text(
                        'Unggah Foto Profil (PB-061)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        side: const BorderSide(color: AppColors.gold),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Atau Pilih Lencana Avatar Anggota:',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_presetAvatars.length, (idx) {
                        final isSelected = _selectedAvatarIndex == idx;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedAvatarIndex = idx),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _presetAvatars[idx]['color'] as Color,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: Icon(
                              _presetAvatars[idx]['icon'] as IconData,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // 2. Field Nama Lengkap
              const Text(
                'Nama Lengkap',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.card,
                  hintText: 'Masukkan nama lengkap',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon:
                      const Icon(Icons.person_outline, color: AppColors.gold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  if (val.trim().length < 3) {
                    return 'Nama minimal 3 karakter';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // 3. Field Nomor Telepon
              const Text(
                'Nomor Telepon / WhatsApp',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.card,
                  hintText: 'Contoh: 081234567890',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon:
                      const Icon(Icons.phone_outlined, color: AppColors.gold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nomor telepon tidak boleh kosong';
                  }
                  if (val.trim().length < 10) {
                    return 'Nomor telepon minimal 10 digit';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // 4. Tombol Simpan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, color: Colors.white),
                  label: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: _saveProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
