import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_network_image.dart';
import '../../data/models/destination_model.dart';
import '../../data/models/trip_model.dart';
import '../explore/destination_provider.dart';
import 'trip_provider.dart';

/// Halaman Tambah & Edit Rencana Trip Multi-Destinasi (Modul 2, 3: State & Controller, Modul 6: Hive CRUD).
class CreateTripScreen extends StatefulWidget {
  final TripModel? existingTrip;
  final DestinationModel? initialDestination;

  const CreateTripScreen({
    super.key,
    this.existingTrip,
    this.initialDestination,
  });

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _dateController;
  late final TextEditingController _budgetController;
  late final TextEditingController _notesController;

  // Daftar destinasi yang dipilih untuk trip ini (Satu Trip Banyak Destinasi)
  List<TripDestinationItem> _selectedDestinations = [];

  bool get isEditing => widget.existingTrip != null;

  @override
  void initState() {
    super.initState();
    final trip = widget.existingTrip;
    _titleController = TextEditingController(
      text: trip?.tripName ?? '',
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

    if (trip != null) {
      _selectedDestinations = List.from(trip.destinations);
    } else if (widget.initialDestination != null) {
      _selectedDestinations = [
        TripDestinationItem.fromDestination(widget.initialDestination!),
      ];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
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

  /// Membuka modal bottom sheet untuk memilih destinasi yang ingin ditambahkan ke trip
  void _openDestinationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final destProvider = context.watch<DestinationProvider>();
            final availableDestinations = destProvider.allDestinations;

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (ctx, scrollController) {
                return Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.margin, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pilih Destinasi Merapi',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_selectedDestinations.length} Dipilih',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: availableDestinations.isEmpty
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.all(AppDimensions.margin),
                              itemCount: availableDestinations.length,
                              itemBuilder: (context, index) {
                                final dest = availableDestinations[index];
                                final isAlreadyAdded = _selectedDestinations.any((item) => item.name == dest.name);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isAlreadyAdded
                                          ? AppColors.primary
                                          : AppColors.outlineVariant.withAlpha(80),
                                      width: isAlreadyAdded ? 1.5 : 1,
                                    ),
                                  ),
                                  color: isAlreadyAdded
                                      ? const Color(0xFFF1F8F5)
                                      : AppColors.surfaceContainerLowest,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 52,
                                        height: 52,
                                        child: AppNetworkImage(
                                          imageUrl: dest.imageUrl,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      dest.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      '${dest.categoryName} • ${dest.elevationMdpl} mdpl • ${dest.formattedTicketPrice}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        isAlreadyAdded ? Icons.check_circle : Icons.add_circle_outline,
                                        color: isAlreadyAdded ? AppColors.primary : AppColors.outline,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (isAlreadyAdded) {
                                            _selectedDestinations.removeWhere((item) => item.name == dest.name);
                                          } else {
                                            _selectedDestinations.add(TripDestinationItem.fromDestination(dest));
                                          }
                                        });
                                        setModalState(() {});
                                      },
                                    ),
                                    onTap: () {
                                      setState(() {
                                        if (isAlreadyAdded) {
                                          _selectedDestinations.removeWhere((item) => item.name == dest.name);
                                        } else {
                                          _selectedDestinations.add(TripDestinationItem.fromDestination(dest));
                                        }
                                      });
                                      setModalState(() {});
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppDimensions.margin),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('Selesai Memilih Destinasi', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _moveDestinationUp(int index) {
    if (index > 0) {
      setState(() {
        final item = _selectedDestinations.removeAt(index);
        _selectedDestinations.insert(index - 1, item);
      });
    }
  }

  void _moveDestinationDown(int index) {
    if (index < _selectedDestinations.length - 1) {
      setState(() {
        final item = _selectedDestinations.removeAt(index);
        _selectedDestinations.insert(index + 1, item);
      });
    }
  }

  void _removeDestination(int index) {
    setState(() {
      _selectedDestinations.removeAt(index);
    });
  }

  void _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDestinations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu destinasi untuk rencana trip ini!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final tripName = _titleController.text.trim();
    final date = _dateController.text.trim();
    final budget = double.tryParse(_budgetController.text.trim()) ?? 250000.0;
    final notes = _notesController.text.trim();

    final provider = context.read<TripProvider>();

    bool success;
    if (isEditing) {
      final updated = widget.existingTrip!.copyWith(
        tripName: tripName,
        startDate: date,
        targetBudget: budget,
        notes: notes,
        destinations: _selectedDestinations,
      );
      success = await provider.updateTrip(updated);
    } else {
      success = await provider.addTrip(
        tripName: tripName,
        startDate: date,
        targetBudget: budget,
        destinations: _selectedDestinations,
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
                : 'Trip baru dengan ${_selectedDestinations.length} destinasi berhasil disimpan ke Hive!',
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
                isEditing ? 'Perbarui Rencana Wisata' : 'Rencana Perjalanan Wisata',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Satu rencana perjalanan dapat memuat banyak destinasi lereng Merapi.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),

              // 1. Nama Trip
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Nama Perjalanan / Trip *',
                  hintText: 'Contoh: Wisata Merapi 2 Hari',
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

              // 2. Tanggal Berangkat
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

              // 3. Target Budget
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

              // 4. Catatan / Perlengkapan
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Catatan & Perlengkapan',
                  hintText: 'Jaket gunung, kamera, jas hujan, tiket...',
                  prefixIcon: const Icon(Icons.notes_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 5. Section: Daftar Destinasi Terpilih (Satu Trip Banyak Destinasi)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DESTINASI PERJALANAN',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.outline,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        '${_selectedDestinations.length} Destinasi Terjadwal',
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => _openDestinationPicker(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tambah Destinasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tampilan List Destinasi Terpilih
              if (_selectedDestinations.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant.withAlpha(80), style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.map_outlined, size: 36, color: AppColors.outline),
                      const SizedBox(height: 8),
                      const Text(
                        'Belum ada destinasi yang dipilih.',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tekan tombol "+ Tambah Destinasi" untuk memilih lokasi wisata.',
                        style: TextStyle(fontSize: 11, color: AppColors.outline),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedDestinations.length,
                  itemBuilder: (context, index) {
                    final item = _selectedDestinations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.outlineVariant.withAlpha(80)),
                      ),
                      color: AppColors.surfaceContainerLowest,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            // Nomor urut destinasi (1, 2, 3...)
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.categoryName} • ${item.elevationMdpl} mdpl',
                                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            // Tombol Urutkan Naik
                            IconButton(
                              icon: const Icon(Icons.arrow_upward, size: 18),
                              tooltip: 'Naikkan urutan',
                              onPressed: index > 0 ? () => _moveDestinationUp(index) : null,
                            ),
                            // Tombol Urutkan Turun
                            IconButton(
                              icon: const Icon(Icons.arrow_downward, size: 18),
                              tooltip: 'Turunkan urutan',
                              onPressed: index < _selectedDestinations.length - 1
                                  ? () => _moveDestinationDown(index)
                                  : null,
                            ),
                            // Tombol Hapus
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                              tooltip: 'Hapus destinasi dari trip',
                              onPressed: () => _removeDestination(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
                    isEditing ? 'Simpan Perubahan Trip' : 'Simpan Rencana Perjalanan',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
