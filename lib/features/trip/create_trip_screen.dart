import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/trip_model.dart';
import 'trip_provider.dart';

/// Halaman Tambah & Edit Rencana Trip (Modul 2, 3: State & Controller, Modul 6: Hive CRUD).
class CreateTripScreen extends StatefulWidget {
  final TripModel? existingTrip;
  final String? initialDestinationName;

  const CreateTripScreen({
    super.key,
    this.existingTrip,
    this.initialDestinationName,
  });

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _destinationController;
  late final TextEditingController _dateController;
  late final TextEditingController _budgetController;
  late final TextEditingController _notesController;

  bool get isEditing => widget.existingTrip != null;

  @override
  void initState() {
    super.initState();
    final trip = widget.existingTrip;
    _titleController = TextEditingController(
      text: trip?.tripName ?? '',
    );
    _destinationController = TextEditingController(
      text: trip?.destinationName ?? widget.initialDestinationName ?? '',
    );
    _dateController = TextEditingController(
      text: trip?.startDate ?? '25 Nov 2026',
    );
    _budgetController = TextEditingController(
      text: trip != null ? trip.targetBudget.toInt().toString() : '250000',
    );
    _notesController = TextEditingController(
      text: trip?.notes ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _dateController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
      setState(() {
        _dateController.text = '${picked.day} ${months[picked.month - 1]} ${picked.year}';
      });
    }
  }

  void _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;

    final tripName = _titleController.text.trim();
    final destination = _destinationController.text.trim();
    final date = _dateController.text.trim();
    final budget = double.tryParse(_budgetController.text.trim()) ?? 250000.0;
    final notes = _notesController.text.trim();

    final provider = context.read<TripProvider>();

    bool success;
    if (isEditing) {
      final updated = widget.existingTrip!.copyWith(
        tripName: tripName,
        destinationName: destination,
        startDate: date,
        targetBudget: budget,
        notes: notes,
      );
      success = await provider.updateTrip(updated);
    } else {
      success = await provider.addTrip(
        tripName: tripName,
        destinationName: destination,
        startDate: date,
        targetBudget: budget,
        notes: notes,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Trip berhasil diperbarui di Hive local storage!'
                : 'Trip baru berhasil disimpan ke Hive local storage!',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      // Modul 4: Kembali ke halaman daftar trip
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menyimpan trip.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Rencana Trip' : 'Tambah Rencana Trip'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.margin),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Perbarui Informasi Trip' : 'Form Perjalanan Baru',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Data trip disimpan secara permanen di memori lokal perangkat (Hive NoSQL Box).',
                style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),

              // 1. Nama Trip
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Nama Perjalanan / Trip *',
                  hintText: 'Contoh: Liburan Keluarga Kaliadem',
                  prefixIcon: const Icon(Icons.luggage_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama trip wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 2. Destinasi
              TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: 'Destinasi Tujuan *',
                  hintText: 'Contoh: Bunker Kaliadem, Museum MGM',
                  prefixIcon: const Icon(Icons.place_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Destinasi tujuan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. Tanggal Berangkat
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: InputDecoration(
                  labelText: 'Tanggal Kunjungan *',
                  prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Pilih tanggal kunjungan';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 4. Target Budget
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Target Anggaran (Rp) *',
                  prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Masukkan nominal anggaran';
                  }
                  if (double.tryParse(val) == null) {
                    return 'Format nominal harus angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 5. Catatan / Perlengkapan
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Catatan & Perlengkapan',
                  hintText: 'Jaket gunung, kamera, jas hujan, tiket...',
                  prefixIcon: const Icon(Icons.notes_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Tombol Simpan
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _saveTrip,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    isEditing ? 'Simpan Perubahan' : 'Buat Rencana Trip',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
