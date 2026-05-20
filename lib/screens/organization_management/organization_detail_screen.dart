import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../../services/auth_provider.dart';
import '../../config/api_config.dart';

class OrganizationDetailScreen extends StatefulWidget {
  const OrganizationDetailScreen({super.key});

  @override
  State<OrganizationDetailScreen> createState() => _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState extends State<OrganizationDetailScreen>
    with SingleTickerProviderStateMixin {
  static const List<_OrganizationTabItem> _tabs = [
    _OrganizationTabItem(
      label: 'Organization Info',
      icon: Icons.apartment_rounded,
    ),
    _OrganizationTabItem(
      label: 'Department',
      icon: Icons.groups_rounded,
    ),
  ];

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text(
          'Organization Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1A1A1A),
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _AnimatedTabPage(
            index: 0,
            animation: _tabController.animation!,
            child: const _OrganizationInfoTab(),
          ),
          _AnimatedTabPage(
            index: 1,
            animation: _tabController.animation!,
            child: const _DepartmentManagementTab(),
          ),
          _AnimatedTabPage(
            index: 2,
            animation: _tabController.animation!,
            child: const _ComplianceManagementTab(),
          ),
          _AnimatedTabPage(
            index: 3,
            animation: _tabController.animation!,
            child: const _DisciplinaryManagementTab(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: _buildBottomTabBar(),
      ),
    );
  }

  Widget _buildBottomTabBar() {
    const double itemSpacing = 8;

    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.72),
                Colors.white.withOpacity(0.46),
              ],
            ),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: Colors.white.withOpacity(0.58),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.10),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth =
                  (constraints.maxWidth - (itemSpacing * (_tabs.length - 1))) /
                      _tabs.length;

              return AnimatedBuilder(
                animation: _tabController.animation!,
                builder: (context, child) {
                  final currentPosition = _tabController.animation!.value.clamp(
                    0.0,
                    (_tabs.length - 1).toDouble(),
                  );
                  final backgroundTravel = tabWidth + itemSpacing;

                  return SizedBox(
                    height: 104,
                    child: Stack(
                      children: [
                        Positioned(
                          left: currentPosition * backgroundTravel,
                          top: lerpDouble(6, 0, _selectedProgress(currentPosition))!,
                          width: tabWidth,
                          height: lerpDouble(92, 104, _selectedProgress(currentPosition))!,
                          child: _SelectedTabBackground(
                            highlightStrength: _selectedProgress(currentPosition),
                          ),
                        ),
                        Row(
                          children: List.generate(_tabs.length, (index) {
                            final item = _tabs[index];
                            final selectionStrength =
                                (1 - (currentPosition - index).abs()).clamp(
                                      0.0,
                                      1.0,
                                    );
                            final iconColor = Color.lerp(
                              const Color(0xFF5B6476),
                              const Color(0xFF2F80FF),
                              selectionStrength,
                            )!;
                            final labelColor = Color.lerp(
                              const Color(0xFF6B7280),
                              const Color(0xFF2F80FF),
                              selectionStrength,
                            )!;
                            final scale =
                                lerpDouble(0.94, 1.0, selectionStrength) ??
                                1.0;
                            final verticalOffset =
                                lerpDouble(0, -4, selectionStrength) ?? 0;
                            final iconOpacity =
                                lerpDouble(0.86, 1.0, selectionStrength) ?? 1.0;
                            final labelOpacity =
                                lerpDouble(0.78, 1.0, selectionStrength) ?? 1.0;

                            return Padding(
                              padding: EdgeInsets.only(
                                right:
                                    index == _tabs.length - 1 ? 0 : itemSpacing,
                              ),
                              child: SizedBox(
                                width: tabWidth,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(28),
                                    onTap: () {
                                      _tabController.animateTo(
                                        index,
                                        duration:
                                            const Duration(milliseconds: 520),
                                        curve: Curves.easeOutBack,
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 18,
                                      ),
                                      child: Transform.translate(
                                        offset: Offset(0, verticalOffset),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Opacity(
                                              opacity: iconOpacity,
                                              child: Transform.scale(
                                                scale: scale,
                                                child: Icon(
                                                  item.icon,
                                                  size: lerpDouble(
                                                    28,
                                                    31,
                                                    selectionStrength,
                                                  ),
                                                  color: iconColor,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: lerpDouble(
                                                8,
                                                10,
                                                selectionStrength,
                                              ),
                                            ),
                                            SizedBox(
                                              width: double.infinity,
                                              child: Opacity(
                                                opacity: labelOpacity,
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    item.label,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                      fontSize: lerpDouble(
                                                        13.5,
                                                        14.4,
                                                        selectionStrength,
                                                      ),
                                                      fontWeight:
                                                          selectionStrength > 0.45
                                                          ? FontWeight.w600
                                                          : FontWeight.w500,
                                                      color: labelColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  double _selectedProgress(double currentPosition) {
    final nearestIndex = currentPosition.round().toDouble();
    return (1 - (currentPosition - nearestIndex).abs() * 2).clamp(0.0, 1.0);
  }
}

class _SelectedTabBackground extends StatelessWidget {
  final double highlightStrength;

  const _SelectedTabBackground({
    required this.highlightStrength,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.72),
            const Color(0xFFE8F1FF).withOpacity(0.60),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(
            lerpDouble(0.42, 0.62, highlightStrength)!,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F80FF).withOpacity(
              lerpDouble(0.06, 0.16, highlightStrength)!,
            ),
            blurRadius: lerpDouble(16, 26, highlightStrength)!,
            offset: Offset(0, lerpDouble(6, 12, highlightStrength)!),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 16,
            right: 16,
            child: Opacity(
              opacity: lerpDouble(0.18, 0.36, highlightStrength)!,
              child: Container(
                height: 26,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.85),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28),
              child: _SelectedTabIndicator(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedTabPage extends StatelessWidget {
  final Widget child;
  final int index;
  final Animation<double> animation;

  const _AnimatedTabPage({
    required this.index,
    required this.child,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final distanceFromCenter = (animation.value - index)
            .abs()
            .clamp(0.0, 1.0);
        final visibility = 1 - distanceFromCenter;
        final opacity = lerpDouble(0.90, 1.0, visibility)!;
        final scale = lerpDouble(0.985, 1.0, visibility)!;
        final verticalOffset = lerpDouble(10, 0, visibility)!;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, verticalOffset),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _SelectedTabIndicator extends StatelessWidget {
  const _SelectedTabIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: const BoxDecoration(
        color: Color(0xFF2F80FF),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(4),
        ),
      ),
    );
  }
}

class _OrganizationInfoTab extends StatefulWidget {
  const _OrganizationInfoTab();

  @override
  State<_OrganizationInfoTab> createState() => _OrganizationInfoTabState();
}

class _OrgSection {
  final TextEditingController legalName = TextEditingController();
  final TextEditingController cin = TextEditingController();
  final TextEditingController gstin = TextEditingController();
  final TextEditingController pan = TextEditingController();
  String? industry;
  String? employeeCount;
  final TextEditingController workWeek = TextEditingController(text: 'Monday - Friday');
  final TextEditingController registeredAddress = TextEditingController();
  final TextEditingController mobile = TextEditingController();
  String countryCode = '+91';
  final TextEditingController email = TextEditingController();
  final TextEditingController website = TextEditingController();
  String? logoPath;
  bool isSister = false;

  void dispose() {
    legalName.dispose();
    cin.dispose();
    gstin.dispose();
    pan.dispose();
    workWeek.dispose();
    registeredAddress.dispose();
    mobile.dispose();
    email.dispose();
    website.dispose();
  }
}

class _OrganizationInfoTabState extends State<_OrganizationInfoTab> {
  List<_OrgSection> _sections = [];
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  final List<String> _industries = ['Healthcare', 'IT & Software', 'Information Technology', 'Finance', 'Education', 'Manufacturing', 'Retail', 'Other'];
  final List<String> _employeeRanges = ['1-10', '11-50', '51-200', '201-500', '500+'];
  final List<String> _countryCodes = ['+91', '+1', '+44', '+61', '+971'];

  @override
  void initState() {
    super.initState();
    _loadOrganizationData();
  }

  Future<void> _loadOrganizationData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user != null) {
        final tokenToUse = authProvider.originalToken ?? user.token;
        final data = await _apiService.fetchOrganizationData(
          user.subInstituteId,
          tokenToUse,
        );

        final orgList = data['org_data'] as List<dynamic>? ?? [];

        final newSections = <_OrgSection>[];

        for (final org in orgList) {
          final section = _OrgSection();
          section.legalName.text = org['legal_name']?.toString() ?? '';
          section.cin.text = org['cin']?.toString() ?? '';
          section.gstin.text = org['gstin']?.toString() ?? '';
          section.pan.text = org['pan']?.toString() ?? '';
          section.industry = org['industry']?.toString() ?? user.orgType;
          section.employeeCount = org['employee_count']?.toString();
          section.workWeek.text = org['work_week']?.toString() ?? '';
          section.registeredAddress.text = org['registered_address']?.toString() ?? '';
          section.mobile.text = org['mobile_no']?.toString() ?? '';
          section.countryCode = org['country_code']?.toString() ?? '+91';
          section.email.text = org['email']?.toString() ?? '';
          section.website.text = org['website']?.toString() ?? '';

          if (org['logo'] != null) {
            section.logoPath = 'https://s3-triz.fra1.cdn.digitaloceanspaces.com/public/hp_logo/${org['logo']}';
          }

          newSections.add(section);

          // Add sister organizations
          final sisters = org['sisters_org'] as List<dynamic>? ?? [];
          for (final sister in sisters) {
            final sisterSection = _OrgSection();
            sisterSection.isSister = true;
            sisterSection.legalName.text = sister['legal_name']?.toString() ?? '';
            sisterSection.cin.text = sister['cin']?.toString() ?? '';
            sisterSection.gstin.text = sister['gstin']?.toString() ?? '';
            sisterSection.pan.text = sister['pan']?.toString() ?? '';
            sisterSection.industry = sister['industry']?.toString();
            sisterSection.employeeCount = sister['employee_count']?.toString();
            sisterSection.workWeek.text = sister['work_week']?.toString() ?? '';
            sisterSection.registeredAddress.text = sister['registered_address']?.toString() ?? '';
            sisterSection.mobile.text = sister['mobile_no']?.toString() ?? '';
            sisterSection.countryCode = sister['country_code']?.toString() ?? '+91';
            sisterSection.email.text = sister['email']?.toString() ?? '';
            sisterSection.website.text = sister['website']?.toString() ?? '';
            newSections.add(sisterSection);
          }
        }

        setState(() {
          _sections = newSections.isNotEmpty ? newSections : [_OrgSection()];
          _isLoading = false;
        });
      } else {
        setState(() {
          _sections = [_OrgSection()];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading organization data: $e');
      setState(() {
        _sections = [_OrgSection()];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    for (final s in _sections) {
      s.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Organization Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF2F80FF), size: 32),
                onPressed: _addNewSection,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 16),
          ..._sections.asMap().entries.map((entry) {
            final index = entry.key;
            final section = entry.value;
            return _buildOrgSectionCard(index, section);
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saveAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F80FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrgSectionCard(int index, _OrgSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                section.isSister ? 'Sister Company' : 'Organization ${index + 1}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              if (section.isSister)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeSection(index),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLogoPicker(section),
          const SizedBox(height: 20),
          _buildField('Legal Name', section.legalName, Icons.business, hint: 'Scholar Clone'),
          const SizedBox(height: 14),
          _buildField('CIN (Corporate Identification Number)', section.cin, Icons.numbers, hint: '123456789'),
          const SizedBox(height: 14),
          _buildField('GSTIN (Optional)', section.gstin, Icons.receipt_long, hint: 'Enter 15-digit GSTIN'),
          const SizedBox(height: 14),
          _buildField('PAN', section.pan, Icons.credit_card, hint: '1123456789'),
          const SizedBox(height: 14),
          _buildDropdown('Industry', section.industry, _industries, (val) => setState(() => section.industry = val)),
          const SizedBox(height: 14),
          _buildDropdown('Employee Count', section.employeeCount, _employeeRanges, (val) => setState(() => section.employeeCount = val)),
          const SizedBox(height: 14),
          _buildField('Work Week', section.workWeek, Icons.schedule, hint: 'Monday to Saturday'),
          const SizedBox(height: 14),
          _buildField('Registered Address', section.registeredAddress, Icons.location_on, maxLines: 2, hint: '201, Sunder chambers...'),
          const SizedBox(height: 14),
          _buildMobileField(section),
          const SizedBox(height: 14),
          _buildField('Email', section.email, Icons.email, keyboardType: TextInputType.emailAddress, hint: 'Enter email address'),
          const SizedBox(height: 14),
          _buildField('Website', section.website, Icons.language, keyboardType: TextInputType.url, hint: 'Enter website URL'),
        ],
      ),
    );
  }

  Widget _buildLogoPicker(_OrgSection section) {
    return Center(
      child: GestureDetector(
        onTap: () => _pickLogo(section),
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
              child: section.logoPath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: section.logoPath!.startsWith('http')
                      ? Image.network(section.logoPath!, fit: BoxFit.cover)
                      : Image.file(File(section.logoPath!), fit: BoxFit.cover),
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 32, color: Color(0xFF64748B)),
                    SizedBox(height: 4),
                    Text('Upload Logo', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Text('PNG, JPG up to 2MB', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon,
      {int maxLines = 1, TextInputType? keyboardType, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileField(_OrgSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mobile Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        const SizedBox(height: 5),
        Row(
          children: [
            Container(
              width: 90,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: section.countryCode,
                  items: _countryCodes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => section.countryCode = val!),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: section.mobile,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '9876543210',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _addNewSection() {
    setState(() {
      final newSection = _OrgSection();
      newSection.isSister = true;
      _sections.add(newSection);
    });
  }

  void _removeSection(int index) {
    setState(() {
      _sections[index].dispose();
      _sections.removeAt(index);
    });
  }

  Future<void> _pickLogo(_OrgSection section) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        section.logoPath = pickedFile.path; // local file path
      });
    }
  }

  Future<void> _saveAll() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user == null) return;

      final tokenToUse = authProvider.originalToken ?? user.token;

      // Prepare data for API
      final submitList = _sections.map((section) => OrgSectionForSubmit(
        legalName: section.legalName.text,
        cin: section.cin.text,
        gstin: section.gstin.text,
        pan: section.pan.text,
        registeredAddress: section.registeredAddress.text,
        mobileNo: section.mobile.text,
        countryCode: section.countryCode,
        email: section.email.text,
        website: section.website.text,
        industry: section.industry,
        employeeCount: section.employeeCount,
        workWeek: section.workWeek.text,
        logoUrl: section.logoPath,
      )).toList();

      await _apiService.submitOrganizationData(
        subInstituteId: user.subInstituteId,
        token: tokenToUse,
        organizations: submitList,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class _DepartmentManagementTab extends StatefulWidget {
  const _DepartmentManagementTab();

  @override
  State<_DepartmentManagementTab> createState() => _DepartmentManagementTabState();
}

class _DepartmentManagementTabState extends State<_DepartmentManagementTab> {
  List<dynamic> _mainDepartments = [];
  Map<String, List<dynamic>> _subDepartments = {};
  bool _isLoading = true;
  bool _showAddForm = false;
  final TextEditingController _newDeptController = TextEditingController();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadDepartmentData();
  }

  @override
  void dispose() {
    _newDeptController.dispose();
    super.dispose();
  }

  void _showAddSubDialog(Map<String, dynamic> parentDept, List<dynamic> currentSubs) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Sub-Department to ${parentDept['department']}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Sub-department name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final user = authProvider.currentUser;
                if (user == null) return;
                final tokenToUse = authProvider.originalToken ?? user.token;
                final parentId = parentDept['id'] as int;
                await _apiService.addSubDepartment(
                  subInstituteId: user.subInstituteId,
                  token: tokenToUse,
                  userId: user.id,
                  department: name,
                  parentId: parentId,
                );
                setState(() {
                  final newSub = {'id': DateTime.now().millisecondsSinceEpoch, 'department': name, 'parent_id': parentId};
                  final key = parentId.toString();
                  if (_subDepartments.containsKey(key)) {
                    _subDepartments[key]!.add(newSub);
                  } else {
                    _subDepartments[key] = [newSub];
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sub-department added')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditSubDialog(Map<String, dynamic> parentDept, Map<String, dynamic> sub) {
    final controller = TextEditingController(text: sub['department'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Sub-Department'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Sub-department name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              final oldName = sub['department'] ?? '';
              if (newName.isEmpty || newName == oldName) {
                Navigator.pop(ctx);
                return;
              }
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final user = authProvider.currentUser;
                if (user == null) return;
                final tokenToUse = authProvider.originalToken ?? user.token;
                await _apiService.editSubDepartment(
                  subInstituteId: user.subInstituteId,
                  token: tokenToUse,
                  userId: user.id,
                  parentDepartmentName: parentDept['department'] ?? '',
                  oldSubDepartment: oldName,
                  newSubDepartment: newName,
                );
                setState(() {
                  final key = parentDept['id'].toString();
                  final subId = sub['id'];
                  final index = _subDepartments[key]!.indexWhere((s) => s['id'] == subId);
                  if (index != -1) {
                    _subDepartments[key]![index] = {
                      ..._subDepartments[key]![index],
                      'department': newName,
                    };
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sub-department updated')));
                _loadDepartmentData(); // refresh from server in background
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDepartmentData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user != null) {
        final tokenToUse = authProvider.originalToken ?? user.token;
        final data = await _apiService.fetchDepartmentManagement(user, tokenToUse);
        setState(() {
          _mainDepartments = data['main_departments'] as List<dynamic>? ?? [];
          final subs = data['sub_departments'] as Map<String, dynamic>? ?? {};
          _subDepartments = subs.map((k, v) => MapEntry(k, (v as List<dynamic>)));
          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      debugPrint('Error loading department data: $e');
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        Row(
          children: [
            const Expanded(child: Text('Department Structure', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2F80FF), Color(0xFF1E5FCC)]), borderRadius: BorderRadius.circular(20)),
              child: Text('${_mainDepartments.length} Departments', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF2F80FF), size: 28),
              onPressed: () => setState(() => _showAddForm = !_showAddForm),
            ),
          ],
        ),
        if (_showAddForm) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add New Department', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                TextField(
                  controller: _newDeptController,
                  decoration: InputDecoration(
                    hintText: 'Enter department name',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = _newDeptController.text.trim();
                      if (name.isEmpty) return;
                      try {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final user = authProvider.currentUser;
                        if (user == null) return;
                        final tokenToUse = authProvider.originalToken ?? user.token;
                        await _apiService.addDepartment(
                          subInstituteId: user.subInstituteId,
                          token: tokenToUse,
                          userId: user.id,
                          department: name,
                        );
                        setState(() {
                          _mainDepartments.insert(0, {'id': DateTime.now().millisecondsSinceEpoch, 'department': name});
                          _newDeptController.clear();
                          _showAddForm = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department added')));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F80FF), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Add Department', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        ..._mainDepartments.map((deptData) {
          final dept = deptData as Map<String, dynamic>;
          final deptId = dept['id'].toString();
          final subs = _subDepartments[deptId] ?? [];
          return Container(
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  backgroundColor: Colors.white,
                  collapsedBackgroundColor: Colors.white,
                  tilePadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  leading: Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFE0EDFF), Color(0xFFC8DFFF)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.apartment_rounded, color: Color(0xFF2F80FF), size: 24),
                  ),
                  title: Text(dept['department'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.1)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(999)),
                        child: Text('${subs.length}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: Color(0xFF2F80FF)),
                        onPressed: () => _showAddSubDialog(dept, subs),
                      ),
                      const Icon(Icons.expand_more_rounded, color: Color(0xFF94A3B8)),
                    ],
                  ),
                  children: subs.isEmpty
                      ? [const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No sub-departments yet', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)))]
                       : subs.map((subData) {
                           final sub = Map<String, dynamic>.from(subData as Map);
                           return Container(
                             margin: const EdgeInsets.only(bottom: 8),
                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                             decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14)),
                             child: Row(children: [
                               Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF94A3B8), shape: BoxShape.circle)),
                               const SizedBox(width: 14),
                               Expanded(child: Text(sub['department'] ?? '', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500, color: Color(0xFF334155)))),
                               IconButton(
                                 icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                                 onPressed: () => _showEditSubDialog(dept, sub),
                               ),
                             ]),
                           );
                         }).toList(),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ComplianceManagementTab extends StatelessWidget {
  const _ComplianceManagementTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Compliance Management Content'),
    );
  }
}

class _DisciplinaryManagementTab extends StatelessWidget {
  const _DisciplinaryManagementTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Disciplinary Management Content'),
    );
  }
}

class _OrganizationTabItem {
  final String label;
  final IconData icon;

  const _OrganizationTabItem({
    required this.label,
    required this.icon,
  });
}
