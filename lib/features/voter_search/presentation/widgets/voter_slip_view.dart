import 'dart:convert';
import 'dart:typed_data';

import 'package:evm_management_system/features/voter_search/data/models/voter_search_models.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Official SEC voter-slip layout (Flutter — correct Devanagari shaping).
///
/// Logical size matches a compact printed slip (~105×148 mm / A6 aspect).
class VoterSlipView extends StatelessWidget {
  const VoterSlipView({
    required this.elector,
    this.photoBase64,
    this.width = slipWidth,
    super.key,
  });

  /// Design width used for preview + image capture.
  static const double slipWidth = 340;

  /// Design height (≈ A6 / printed slip proportions).
  static const double slipHeight = 480;

  static const Locale _hi = Locale('hi', 'IN');
  static const String _logoAsset = 'assets/images/voter_slip_sec_icon.png';

  final VoterElector elector;
  final String? photoBase64;
  final double width;

  /// Devanagari primary + Latin fallback so English names stay "Himanshu"
  /// (not mangled) and Hindi stays "वोटर स्लिप" (not broken conjuncts).
  static TextStyle _textStyle(
    double fontSize, {
    FontWeight fontWeight = FontWeight.w400,
    Color color = Colors.black,
    double height = 1.3,
  }) {
    return TextStyle(
      fontFamily: AppTextStyles.devanagariFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    ).copyWith(
      fontFamilyFallback: <String>[
        AppTextStyles.fontFamily,
        'Roboto',
        'sans-serif',
      ],
    );
  }

  Uint8List? get _photoBytes {
    final String? raw = photoBase64;
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      String value = raw.trim();
      if (value.contains(',')) value = value.split(',').last.trim();
      value = value.replaceAll(RegExp(r'\s+'), '');
      final int mod = value.length % 4;
      if (mod > 0) value = value.padRight(value.length + (4 - mod), '=');
      final Uint8List bytes = base64Decode(value);
      if (bytes.length < 64) return null;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  String get _headerTitle {
    if (elector.panchayatName.isNotEmpty ||
        elector.blockName.isNotEmpty ||
        elector.elecType.toUpperCase().contains('R')) {
      return 'त्रि-स्तरीय पंचायतों का निर्वाचन';
    }
    if (elector.ubName.isNotEmpty || elector.ubTypeName.isNotEmpty) {
      return 'नगरीय निकायों का निर्वाचन';
    }
    return 'त्रि-स्तरीय पंचायतों का निर्वाचन';
  }

  @override
  Widget build(BuildContext context) {
    final double scale = width / slipWidth;
    final double height = slipHeight * scale;
    final Uint8List? photo = _photoBytes;

    final String wardNo = elector.wardNo.isEmpty ? '—' : elector.wardNo;
    final String serNo = elector.serNo.isEmpty ? '—' : elector.serNo;
    final String name = elector.name.isEmpty ? '—' : elector.name;
    final String relative = elector.rlnName.isEmpty ? '—' : elector.rlnName;
    final String gender = elector.gender.isEmpty ? '—' : elector.gender;
    final String bodyName =
        elector.slipBodyName.isEmpty ? '—' : elector.slipBodyName;
    final String address =
        elector.slipAddressLine.isEmpty ? '—' : elector.slipAddressLine;

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1 * scale),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            14 * scale,
            12 * scale,
            14 * scale,
            12 * scale,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Image.asset(
                    _logoAsset,
                    width: 46 * scale,
                    height: 38 * scale,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => SizedBox(
                      width: 46 * scale,
                      height: 38 * scale,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        Text(
                          _headerTitle,
                          textAlign: TextAlign.center,
                          locale: _hi,
                          style: _textStyle(12 * scale, height: 1.25),
                        ),
                        SizedBox(height: 2 * scale),
                        Text(
                          'वोटर स्लिप',
                          textAlign: TextAlign.center,
                          locale: _hi,
                          style: _textStyle(
                            17 * scale,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 46 * scale),
                ],
              ),
              SizedBox(height: 12 * scale),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _line(
                          elector.isUrban
                              ? 'नगरीय निकाय का नाम : '
                              : 'पंचायत का नाम : ',
                          bodyName,
                          scale,
                        ),
                        SizedBox(height: 6 * scale),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _line(
                                elector.isUrban
                                    ? 'वार्ड क्रमांक (शहरी) : '
                                    : 'वार्ड क्रमांक (ग्रामीण) : ',
                                wardNo,
                                scale,
                              ),
                            ),
                            Expanded(
                              child: _line('मतदाता क्र. ', serNo, scale),
                            ),
                          ],
                        ),
                        SizedBox(height: 6 * scale),
                        _line(
                          'मतदाता का नाम : ',
                          name,
                          scale,
                          valueBold: true,
                        ),
                        SizedBox(height: 6 * scale),
                        _line(
                          '${elector.relativeLabel} : ',
                          relative,
                          scale,
                          valueBold: true,
                        ),
                        SizedBox(height: 6 * scale),
                        _line('लिंग : ', gender, scale),
                        SizedBox(height: 6 * scale),
                        _line('पता : ', address, scale),
                      ],
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  Container(
                    width: 78 * scale,
                    height: 96 * scale,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF757575),
                        width: 0.7 * scale,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    child: photo == null
                        ? Text(
                            'फोटो',
                            locale: _hi,
                            style: _textStyle(
                              9 * scale,
                              color: const Color(0xFF9E9E9E),
                            ),
                          )
                        : Image.memory(
                            photo,
                            fit: BoxFit.cover,
                            width: 78 * scale,
                            height: 96 * scale,
                            errorBuilder: (_, __, ___) => Text(
                              'फोटो',
                              locale: _hi,
                              style: _textStyle(
                                9 * scale,
                                color: const Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              SizedBox(height: 10 * scale),
              _line(
                'मतदान केन्द्र क्रमांक, नाम एवं पता : ',
                elector.boothLine,
                scale,
              ),
              SizedBox(height: 12 * scale),
              Text(
                'नोट 1: इस वोटर स्लिप को पहचान दस्तावेज के रूप में भी प्रस्तुत किया जा सकता है।',
                locale: _hi,
                style: _textStyle(9 * scale, height: 1.35),
              ),
              SizedBox(height: 6 * scale),
              Text(
                'नोट 2: यदि वोटर स्लिप पर फोटोग्राफ उपलब्ध नहीं है अथवा त्रुटिपूर्ण है '
                'अथवा अन्य प्रविष्टियां त्रुटिपूर्ण है तो भी मतदाता को राज्य निर्वाचन आयोग '
                'द्वारा जारी वैकल्पिक दस्तावेजों के आधार पर मतदान करने की अनुमति होगी।',
                locale: _hi,
                style: _textStyle(9 * scale, height: 1.35),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'दिनांक : ..................',
                      locale: _hi,
                      style: _textStyle(10 * scale),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        'हस्ताक्षर एवं सील',
                        locale: _hi,
                        style: _textStyle(10 * scale),
                      ),
                      SizedBox(height: 2 * scale),
                      Text(
                        'रिटर्निंग अधिकारी / सहायक रिटर्निंग अधिकारी.',
                        locale: _hi,
                        style: _textStyle(8.5 * scale),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _line(
    String label,
    String value,
    double scale, {
    bool valueBold = false,
  }) {
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: label,
            locale: _hi,
            style: _textStyle(11 * scale),
          ),
          TextSpan(
            text: value,
            locale: _hi,
            style: _textStyle(
              11 * scale,
              fontWeight: valueBold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
      locale: _hi,
    );
  }
}
