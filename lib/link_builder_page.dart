import 'dart:convert';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_lib;
import 'package:qr_flutter/qr_flutter.dart';

import 'app_config.dart';
import 'browser_navigation.dart';
import 'smart_link.dart';

class LinkBuilderPage extends StatefulWidget {
  const LinkBuilderPage({
    super.key,
    required this.defaultConfig,
    required this.currentUri,
  });

  final AppConfig defaultConfig;
  final Uri currentUri;

  @override
  State<LinkBuilderPage> createState() => _LinkBuilderPageState();
}

class _LinkBuilderPageState extends State<LinkBuilderPage> {
  final _formKey = GlobalKey<FormState>();
  final _resultKey = GlobalKey();
  final _qrBoundaryKey = GlobalKey();

  late final TextEditingController _iosController;
  late final TextEditingController _androidController;
  late final TextEditingController _appNameController;

  Uri? _generatedUrl;
  Uint8List? _logoPreviewBytes;
  String? _logoDataUrl;
  String? _logoFileName;
  bool _isPickingLogo = false;
  bool _isDownloadingQr = false;

  @override
  void initState() {
    super.initState();
    final config = widget.defaultConfig;
    _iosController = TextEditingController(
      text: _usableDefault(config.appStoreUrl),
    );
    _androidController = TextEditingController(
      text: _usableDefault(config.googlePlayUrl),
    );
    _appNameController = TextEditingController();
  }

  String _usableDefault(Uri uri) {
    final value = uri.toString();
    if (value.contains('YOUR_APP_ID') || value.contains('com.example.app')) {
      return '';
    }
    return value;
  }

  @override
  void dispose() {
    _iosController.dispose();
    _androidController.dispose();
    _appNameController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    setState(() => _isPickingLogo = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (!mounted || result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        _showMessage('The selected image could not be read.');
        return;
      }
      if (file.size > 10 * 1024 * 1024) {
        _showMessage('Choose an image smaller than 10 MB.');
        return;
      }

      final decoded = image_lib.decodeImage(bytes);
      if (decoded == null) {
        _showMessage('Choose a supported PNG, JPEG, WebP, GIF, or BMP image.');
        return;
      }

      final thumbnail = image_lib.copyResize(
        decoded,
        width: 32,
        height: 32,
        maintainAspect: true,
        interpolation: image_lib.Interpolation.average,
      );
      final optimized = image_lib.encodeJpg(thumbnail, quality: 40);

      setState(() {
        _logoPreviewBytes = bytes;
        _logoDataUrl = 'data:image/jpeg;base64,${base64Encode(optimized)}';
        _logoFileName = file.name;
      });
    } on Object {
      if (mounted) {
        _showMessage('The image picker could not be opened.');
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingLogo = false);
      }
    }
  }

  void _removeLogo() {
    setState(() {
      _logoPreviewBytes = null;
      _logoDataUrl = null;
      _logoFileName = null;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Uri? _httpsUri(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return null;
    }
    return uri;
  }

  String? _requiredUrlValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This link is required.';
    }
    if (_httpsUri(value) == null) {
      return 'Enter a complete HTTPS link.';
    }
    return null;
  }

  String? _requiredNameValidator(String? value) {
    return value == null || value.trim().isEmpty ? 'Enter the app name.' : null;
  }

  void _generate() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final appName = _appNameController.text.trim();
    final smartLink = SmartLink(
      appName: appName,
      logoPath: _logoDataUrl ?? widget.defaultConfig.logoPath,
      appStoreUrl: _httpsUri(_iosController.text)!,
      googlePlayUrl: _httpsUri(_androidController.text)!,
    );

    setState(() {
      _generatedUrl = smartLink.shareUri(widget.currentUri);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final resultContext = _resultKey.currentContext;
      if (resultContext != null) {
        Scrollable.ensureVisible(
          resultContext,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          alignment: 0.08,
        );
      }
    });
  }

  Future<void> _copyLink() async {
    final url = _generatedUrl;
    if (url == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: url.toString()));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Smart download link copied.')),
    );
  }

  Future<void> _downloadQr() async {
    final boundary =
        _qrBoundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      _showMessage('The QR image is not ready yet.');
      return;
    }

    setState(() => _isDownloadingQr = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final image = await boundary.toImage(pixelRatio: 4);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw StateError('Could not create QR image.');
      }

      final slug = _appNameController.text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
      await FilePicker.saveFile(
        fileName: '${slug.isEmpty ? 'app' : slug}-qr.png',
        type: FileType.custom,
        allowedExtensions: const ['png'],
        bytes: data.buffer.asUint8List(),
      );
      if (mounted) {
        _showMessage('QR image downloaded.');
      }
    } on Object {
      if (mounted) {
        _showMessage('The QR image could not be downloaded.');
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingQr = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 44),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create your smart download QR',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: const Color(0xFF202735),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter each destination once. Your QR will send visitors to the right store automatically.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF737B88),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 36),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFFE2E6EB)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x10202C45),
                          blurRadius: 40,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 16 : 28,
                        compact ? 24 : 34,
                        compact ? 16 : 28,
                        compact ? 22 : 30,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _InputWithHelp(
                              controller: _iosController,
                              hintText: 'Link for App Store',
                              prefix: const Icon(
                                Icons.apple,
                                color: Color(0xFF202735),
                                size: 28,
                              ),
                              helpText:
                                  'Enter the link to the application in the App Store for iOS devices.',
                              validator: _requiredUrlValidator,
                              keyboardType: TextInputType.url,
                            ),
                            _InputWithHelp(
                              controller: _androidController,
                              hintText: 'Link for Google Play',
                              prefix: Image.asset(
                                'assets/playstore.png',
                                width: 28,
                              ),
                              helpText:
                                  'Enter the Google Play link for Android devices.',
                              validator: _requiredUrlValidator,
                              keyboardType: TextInputType.url,
                            ),
                            _InputWithHelp(
                              controller: _appNameController,
                              hintText: 'App name',
                              helpText:
                                  'The app name displayed on the desktop download page.',
                              validator: _requiredNameValidator,
                            ),
                            _LogoPicker(
                              bytes: _logoPreviewBytes,
                              fileName: _logoFileName,
                              isPicking: _isPickingLogo,
                              onPick: _pickLogo,
                              onRemove: _removeLogo,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: FilledButton.icon(
                                onPressed: _generate,
                                icon: const Icon(Icons.qr_code_2_rounded),
                                label: const Text(
                                  'Create QR code',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF202735),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_generatedUrl case final url?) ...[
                    const SizedBox(height: 28),
                    _ResultCard(
                      key: _resultKey,
                      url: url,
                      qrBoundaryKey: _qrBoundaryKey,
                      logoBytes: _logoPreviewBytes,
                      fallbackLogoPath: widget.defaultConfig.logoPath,
                      isDownloading: _isDownloadingQr,
                      onDownload: _downloadQr,
                      onCopy: _copyLink,
                      onOpen: () => assignLocation(url),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputWithHelp extends StatelessWidget {
  const _InputWithHelp({
    required this.controller,
    required this.hintText,
    required this.helpText,
    this.prefix,
    this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hintText;
  final String helpText;
  final Widget? prefix;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              autocorrect: false,
              enableSuggestions: false,
              style: TextStyle(
                color: const Color(0xFF303846),
                fontSize: compact ? 15.5 : 18,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: prefix == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(left: 16, right: 12),
                        child: SizedBox(width: 30, height: 30, child: prefix),
                      ),
                prefixIconConstraints: const BoxConstraints(minWidth: 58),
                hintStyle: TextStyle(
                  color: const Color(0xFF8B939E),
                  fontSize: compact ? 15.5 : 18,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: compact ? 16 : 24,
                  vertical: 24,
                ),
                filled: true,
                fillColor: const Color(0xFFFDFDFE),
                border: _border(const Color(0xFFDCE1E6)),
                enabledBorder: _border(const Color(0xFFDCE1E6)),
                focusedBorder: _border(const Color(0xFF5D68E8), width: 2),
                errorBorder: _border(const Color(0xFFD74B4B)),
                focusedErrorBorder: _border(const Color(0xFFD74B4B), width: 2),
              ),
            ),
          ),
          SizedBox(width: compact ? 11 : 18),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Tooltip(
              message: helpText,
              triggerMode: TooltipTriggerMode.tap,
              showDuration: const Duration(seconds: 5),
              preferBelow: false,
              verticalOffset: 22,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xEE303030),
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.35,
              ),
              child: Icon(
                Icons.help_outline_rounded,
                color: const Color(0xFF384656),
                size: compact ? 34 : 38,
              ),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1.5}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _LogoPicker extends StatelessWidget {
  const _LogoPicker({
    required this.bytes,
    required this.fileName,
    required this.isPicking,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? bytes;
  final String? fileName;
  final bool isPicking;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    final hasImage = bytes != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 88),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 14 : 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFDFE),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFDCE1E6), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasImage
                        ? Image.memory(bytes!, fit: BoxFit.cover)
                        : const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Color(0xFF7E8794),
                            size: 28,
                          ),
                  ),
                  SizedBox(width: compact ? 12 : 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName ?? 'Choose app logo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF303846),
                            fontSize: compact ? 15 : 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'PNG, JPEG, WebP, GIF or BMP · max 10 MB',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF8B939E),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPicking)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  else if (hasImage)
                    IconButton(
                      onPressed: onRemove,
                      tooltip: 'Remove selected logo',
                      icon: const Icon(Icons.close_rounded),
                    )
                  else
                    OutlinedButton(
                      onPressed: onPick,
                      child: Text(compact ? 'Browse' : 'Choose image'),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: compact ? 11 : 18),
          Tooltip(
            message:
                'Choose a logo from your device. It is optimized and embedded in the smart QR link.',
            triggerMode: TooltipTriggerMode.tap,
            showDuration: const Duration(seconds: 5),
            preferBelow: false,
            child: Icon(
              Icons.help_outline_rounded,
              color: const Color(0xFF384656),
              size: compact ? 34 : 38,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    super.key,
    required this.url,
    required this.qrBoundaryKey,
    required this.logoBytes,
    required this.fallbackLogoPath,
    required this.isDownloading,
    required this.onDownload,
    required this.onCopy,
    required this.onOpen,
  });

  final Uri url;
  final GlobalKey qrBoundaryKey;
  final Uint8List? logoBytes;
  final String fallbackLogoPath;
  final bool isDownloading;
  final VoidCallback onDownload;
  final VoidCallback onCopy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E6EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final ImageProvider<Object> logo = logoBytes == null
                ? AssetImage(fallbackLogoPath)
                : MemoryImage(logoBytes!);
            final qr = RepaintBoundary(
              key: qrBoundaryKey,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE3E6EA)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: QrImageView(
                    data: url.toString(),
                    size: 220,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.Q,
                    embeddedImage: logo,
                    embeddedImageStyle: const QrEmbeddedImageStyle(
                      size: Size.square(42),
                    ),
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF202735),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF202735),
                    ),
                  ),
                ),
              ),
            );
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your smart QR is ready',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF202735),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Use this QR or copy its destination link. The store links are encoded in the URL.',
                  style: TextStyle(color: Color(0xFF737B88), height: 1.45),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    url.toString(),
                    style: const TextStyle(
                      color: Color(0xFF4E5766),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: isDownloading ? null : onDownload,
                      icon: isDownloading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(isDownloading ? 'Preparing…' : 'Download QR'),
                    ),
                    FilledButton.icon(
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy link'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open download page'),
                    ),
                  ],
                ),
              ],
            );

            if (compact) {
              return Column(
                children: [qr, const SizedBox(height: 24), details],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                qr,
                const SizedBox(width: 32),
                Expanded(child: details),
              ],
            );
          },
        ),
      ),
    );
  }
}
