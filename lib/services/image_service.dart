import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Servicio para gestionar imágenes de productos
class ImageService {
  final ImagePicker _picker = ImagePicker();

  // Colores de la app para el cropper
  static const Color nexusYellow = Color(0xFFFFDE00);
  static const Color nexusBlue = Color(0xFF00187A);

  /// Seleccionar imagen desde cámara o galería y recortarla
  Future<File?> pickAndCropImage({required ImageSource source}) async {
    try {
      // 1. Seleccionar imagen
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Calidad 85% para reducir tamaño
      );

      if (pickedFile == null) return null;

      // 2. Recortar imagen a cuadrado
      final croppedFile = await _cropImage(pickedFile.path);

      if (croppedFile == null) return null;

      // 3. Guardar en almacenamiento permanente
      final savedFile = await _saveImagePermanently(croppedFile.path);

      return savedFile;
    } catch (e) {
      print('Error al seleccionar/recortar imagen: $e');
      return null;
    }
  }

  /// Recortar imagen a formato cuadrado
  Future<CroppedFile?> _cropImage(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Cuadrado
        compressQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
        uiSettings: [
          // Configuración para Android
          AndroidUiSettings(
            toolbarTitle: 'Recortar Imagen',
            toolbarColor: nexusBlue,
            toolbarWidgetColor: nexusYellow,
            activeControlsWidgetColor: nexusYellow,
            backgroundColor: const Color(0xFF000F4D),
            cropGridColor: nexusYellow,
            lockAspectRatio: true, // Bloquear aspecto cuadrado
            hideBottomControls: false,
          ),
          // Configuración para iOS
          IOSUiSettings(
            title: 'Recortar Imagen',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      return croppedFile;
    } catch (e) {
      print('Error al recortar imagen: $e');
      return null;
    }
  }

  /// Guardar imagen en almacenamiento permanente de la app
  Future<File> _saveImagePermanently(String tempPath) async {
    // Obtener directorio de documentos de la app
    final appDir = await getApplicationDocumentsDirectory();
    final productImagesDir = Directory('${appDir.path}/product_images');

    // Crear directorio si no existe
    if (!await productImagesDir.exists()) {
      await productImagesDir.create(recursive: true);
    }

    // Generar nombre único usando timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(tempPath);
    final fileName = 'product_$timestamp$extension';
    final savedPath = '${productImagesDir.path}/$fileName';

    // Copiar archivo temporal a ubicación permanente
    final File tempFile = File(tempPath);
    final File savedFile = await tempFile.copy(savedPath);

    return savedFile;
  }

  /// Eliminar imagen del almacenamiento
  Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error al eliminar imagen: $e');
      return false;
    }
  }

  /// Mostrar diálogo para elegir entre cámara o galería
  static Future<ImageSource?> showImageSourceDialog(BuildContext context) async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        const nexusYellow = Color(0xFFFFDE00);
        const nexusBlue = Color(0xFF00187A);

        return AlertDialog(
          backgroundColor: nexusBlue,
          title: const Text(
            'Seleccionar imagen',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // OPCIÓN: CÁMARA
              ListTile(
                leading: const Icon(Icons.camera_alt, color: nexusYellow, size: 32),
                title: const Text(
                  'Tomar foto',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const Divider(color: Colors.white24),
              // OPCIÓN: GALERÍA
              ListTile(
                leading: const Icon(Icons.photo_library, color: nexusYellow, size: 32),
                title: const Text(
                  'Elegir de galería',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        );
      },
    );
  }
}