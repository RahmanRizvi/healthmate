import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../viewmodels/progress_viewmodel.dart';
import 'progress_report_card.dart';

/// Modal dialog providing interactive preview and download of the HealthMate report image directly to the gallery.
class ProgressExportDialog extends StatefulWidget {
  final ProgressViewModel viewModel;

  const ProgressExportDialog({
    super.key,
    required this.viewModel,
  });

  static Future<void> show(BuildContext context, ProgressViewModel viewModel) {
    return showDialog(
      context: context,
      builder: (_) => ProgressExportDialog(viewModel: viewModel),
    );
  }

  @override
  State<ProgressExportDialog> createState() => _ProgressExportDialogState();
}

class _ProgressExportDialogState extends State<ProgressExportDialog> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isSaving = false;
  String? _savedFilePath;
  bool _savedToGallery = false;

  Future<void> _downloadImage() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Render boundary not found');
      }

      // Capture at high resolution (pixelRatio: 3.0 for sharp, crisp image)
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to encode image to PNG');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final periodName = widget.viewModel.periodType.name;
      final fileName = 'healthmate_${periodName}_report_$timestamp.png';

      // 1. Save directly into device Photos / Gallery
      bool galSuccess = false;
      try {
        await Gal.putImageBytes(pngBytes, name: fileName);
        galSuccess = true;
      } catch (_) {
        // Fallback for environments where Gal native channel is unavailable
        galSuccess = false;
      }

      // 2. Also save to device documents/downloads for file access
      Directory? targetDir;
      try {
        targetDir = await getDownloadsDirectory();
      } catch (_) {
        targetDir = null;
      }

      targetDir ??= await getApplicationDocumentsDirectory();
      final file = File('${targetDir.path}/$fileName');
      await file.writeAsBytes(pngBytes, flush: true);

      setState(() {
        _savedFilePath = file.path;
        _savedToGallery = galSuccess;
      });

      if (mounted) {
        final message = galSuccess
            ? 'Saved report image directly to your Gallery!'
            : 'Saved report image to: $fileName';

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            dismissDirection: DismissDirection.horizontal,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 12.5, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text('Failed to save image: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _copyCsv() {
    final csv = widget.viewModel.generateCsvReport();
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV report copied to clipboard!'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final data = vm.analyticsData;

    if (data == null) {
      return const AlertDialog(
        content: Text('No data available to export.'),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        ),
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: const [
                        Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Save Report to Gallery',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Preview your branded health card with app logo, ready to save directly to Photos.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Image Card Preview wrapped in RepaintBoundary for capture
              RepaintBoundary(
                key: _boundaryKey,
                child: ProgressReportCard(
                  data: data,
                  insight: vm.currentInsight,
                ),
              ),

              const SizedBox(height: 18),

              if (_savedFilePath != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _savedToGallery
                              ? 'Saved to Gallery & $_savedFilePath'
                              : 'Saved: $_savedFilePath',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF15803D)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF15803D)),
                        tooltip: 'Copy file path',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _savedFilePath!));
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('File path copied to clipboard!'),
                              backgroundColor: AppColors.primary,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Action Buttons
              Row(
                children: [
                  // Copy CSV Option
                  OutlinedButton.icon(
                    onPressed: _copyCsv,
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('CSV'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Save to Gallery Primary Action
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _downloadImage,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.photo_library_rounded, size: 18),
                      label: Text(
                        _isSaving ? 'Saving...' : 'Save to Gallery',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
