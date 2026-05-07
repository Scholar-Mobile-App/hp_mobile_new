import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/menu.dart';
import '../../../models/jobrole.dart';
import '../../../models/job_role_task_table.dart';
import '../../../models/user_knowledge.dart';
import '../../../models/user_ability.dart';
import '../../../models/user_behaviour.dart';
import '../../../models/user_attitude.dart';
import '../../../services/auth_provider.dart';
import '../../../services/api_service.dart';
import 'skill_detail_screen.dart';
import 'job_role_detail_screen.dart';
import 'jobrole_task_screen.dart';
import 'knowledge_detail_screen.dart';
import 'ability_detail_screen.dart';
import 'attitude_screen.dart';


class LibraryTaxonomyScreen extends StatefulWidget {
  final MenuItem menuItem;

  const LibraryTaxonomyScreen({Key? key, required this.menuItem}) : super(key: key);

  @override
  _LibraryTaxonomyScreenState createState() => _LibraryTaxonomyScreenState();
}

class _LibraryTaxonomyScreenState extends State<LibraryTaxonomyScreen> {
  String selectedMenu = 'Skill'; // Default selected
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;
  Set<String> selectedDepartments = {};
  Set<String> selectedCategories = {};
  Set<String> selectedSubCategories = {};
  Set<String> selectedProficiencyLevels = {};
  List<dynamic> allSkills = [];
  List<JobRole> allJobRoles = [];
  List<UserKnowledge> allKnowledge = [];
  List<UserAbility> allAbilities = [];
  List<UserBehaviour> allBehaviours = [];
  List<UserAttitude> allAttitudes = [];
  Set<String> selectedKnowledgeCategories = {};
  Set<String> selectedKnowledgeSubCategories = {};
  Set<String> selectedAbilityCategories = {};
  Set<String> selectedAbilitySubCategories = {};
  Set<String> selectedBehaviourCategories = {};
  Set<String> selectedBehaviourSubCategories = {};

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<List<dynamic>> _getSkills() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) throw Exception('No user available');
    final token = auth.originalToken ?? user.token;
    return await _apiService.fetchSkillLibrary(user, token);
  }

  Future<List<JobRole>> _getJobRoles() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) throw Exception('No user available');
    final token = auth.originalToken ?? user.token;
    final data = await _apiService.fetchJobRoles(user, token);
    return data.map((json) => JobRole.fromJson(json)).toList();
  }

  Future<List<UserKnowledge>> _getUserKnowledge() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) throw Exception('No user available');
    final token = auth.originalToken ?? user.token;
    return await _apiService.fetchUserKnowledge(user, token);
  }

  Future<List<UserAbility>> _getUserAbility() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) throw Exception('No user available');
    final token = auth.originalToken ?? user.token;
    return await _apiService.fetchUserAbility(user, token);
  }

  Future<List<UserBehaviour>> _getUserBehaviour() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) throw Exception('No user available');
    final token = auth.originalToken ?? user.token;
    return await _apiService.fetchUserBehaviour(user, token);
  }

  Future<List<UserAttitude>> _getUserAttitude() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) throw Exception('No user available');
    final token = auth.originalToken ?? user.token;
    final data = await _apiService.fetchAttitudes(user, token);
    return data.map((json) => UserAttitude.fromJson(json)).toList();
  }

  void _showAbilityFilterDialog(BuildContext context) {
    final categories = allAbilities.map((a) => a.category?.toString() ?? '').toSet().where((s) => s.isNotEmpty).toList()..sort();
    final subCategories = allAbilities.map((a) => a.subCategory?.toString() ?? '').toSet().where((s) => s.isNotEmpty).toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottom) {
            return Container(
              padding: EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                children: [
                  Text('Ability Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2A6D))),
                  SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterSection('Category', categories, selectedAbilityCategories, setStateBottom),
                          _buildFilterSection('Sub-Category', subCategories, selectedAbilitySubCategories, setStateBottom),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedAbilityCategories.clear();
                            selectedAbilitySubCategories.clear();
                          });
                          setStateBottom(() {});
                          Navigator.pop(context);
                        },
                        child: Text('Clear All', style: TextStyle(color: Colors.red)),
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF6A00),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    if (selectedMenu == 'Skill') {
      final departments = allSkills.map((s) => s['department']?.toString() ?? '').toSet().where((s) => s.isNotEmpty).toList()..sort();
      final categories = allSkills.map((s) => s['category']?.toString() ?? '').toSet().where((s) => s.isNotEmpty).toList()..sort();
      final subCategories = allSkills.map((s) => s['sub_category']?.toString() ?? '').toSet().where((s) => s.isNotEmpty).toList()..sort();
      final proficiencyLevels = allSkills.map((s) => s['proficiency_level']?.toString() ?? '').toSet().where((s) => s.isNotEmpty).toList()..sort();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateBottom) {
              return Container(
                padding: EdgeInsets.all(16),
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  children: [
                    Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2A6D))),
                    SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFilterSection('Department', departments, selectedDepartments, setStateBottom),
                            _buildFilterSection('Category', categories, selectedCategories, setStateBottom),
                            _buildFilterSection('Sub-Category', subCategories, selectedSubCategories, setStateBottom),
                            _buildFilterSection('Proficiency Level', proficiencyLevels, selectedProficiencyLevels, setStateBottom),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedDepartments.clear();
                              selectedCategories.clear();
                              selectedSubCategories.clear();
                              selectedProficiencyLevels.clear();
                            });
                            setStateBottom(() {});
                            Navigator.pop(context);
                          },
                          child: Text('Clear All', style: TextStyle(color: Colors.red)),
                        ),
                        Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF6A00),
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    if (selectedMenu == 'Job Role') {
      final departments = allJobRoles.map((j) => j.department).toSet().where((d) => d.isNotEmpty).toList()..sort();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateBottom) {
              return Container(
                padding: EdgeInsets.all(16),
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2A6D))),
                    SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFilterSection('Department', departments, selectedDepartments, setStateBottom),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedDepartments.clear();
                            });
                            setStateBottom(() {});
                            Navigator.pop(context);
                          },
                          child: Text('Clear All', style: TextStyle(color: Colors.red)),
                        ),
                        Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF6A00),
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }
  }

  void _showBehaviourFilterDialog(BuildContext context) {
    final categories = allBehaviours.map((b) => b.category).where((c) => c != null && c.isNotEmpty).cast<String>().toSet().toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottom) {
            // Get sub-categories based on selected categories
            final List<String> availableSubCategories;
            if (selectedBehaviourCategories.isEmpty) {
              availableSubCategories = allBehaviours
                  .map((b) => b.subCategory)
                  .where((s) => s != null && s.isNotEmpty)
                  .cast<String>()
                  .toSet()
                  .toList()..sort();
            } else {
              availableSubCategories = allBehaviours
                  .where((b) => selectedBehaviourCategories.contains(b.category))
                  .map((b) => b.subCategory)
                  .where((s) => s != null && s.isNotEmpty)
                  .cast<String>()
                  .toSet()
                  .toList()..sort();
            }

            return Container(
              padding: EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Text('Behaviour Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2A6D))),
                  SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterSection('Category', categories, selectedBehaviourCategories, setStateBottom),
                          SizedBox(height: 16),
                          _buildFilterSection('Sub-Category', availableSubCategories, selectedBehaviourSubCategories, setStateBottom),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedBehaviourCategories.clear();
                            selectedBehaviourSubCategories.clear();
                          });
                          setStateBottom(() {});
                          Navigator.pop(context);
                        },
                        child: Text('Clear All', style: TextStyle(color: Colors.red)),
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF6A00),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showKnowledgeFilterDialog(BuildContext context) {
    final categories = allKnowledge
        .map((k) => k.category)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottom) {
            // Get sub-categories based on selected categories
            final List<String> availableSubCategories;
            if (selectedKnowledgeCategories.isEmpty) {
              availableSubCategories = allKnowledge
                  .map((k) => k.subCategory)
                  .where((s) => s != null && s.isNotEmpty)
                  .cast<String>()
                  .toSet()
                  .toList()..sort();
            } else {
              availableSubCategories = allKnowledge
                  .where((k) => selectedKnowledgeCategories.contains(k.category))
                  .map((k) => k.subCategory)
                  .where((s) => s != null && s.isNotEmpty)
                  .cast<String>()
                  .toSet()
                  .toList()..sort();
            }

            return Container(
              padding: EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Text('Knowledge Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2A6D))),
                  SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterSection('Category', categories, selectedKnowledgeCategories, setStateBottom),
                          SizedBox(height: 16),
                          _buildFilterSection('Sub-Category', availableSubCategories, selectedKnowledgeSubCategories, setStateBottom),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedKnowledgeCategories.clear();
                            selectedKnowledgeSubCategories.clear();
                          });
                          setStateBottom(() {});
                          Navigator.pop(context);
                        },
                        child: Text('Clear All', style: TextStyle(color: Colors.red)),
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF6A00),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection(String title, List<String> options, Set<String> selected, StateSetter setStateBottom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2A6D))),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option, style: TextStyle(color: isSelected ? Colors.white : Color(0xFF1F2A6D))),
              selected: isSelected,
              onSelected: (bool value) {
                setStateBottom(() {
                  if (value) {
                    selected.add(option);
                  } else {
                    selected.remove(option);
                  }
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Color(0xFFFF6A00),
              checkmarkColor: Colors.white,
            );
          }).toList(),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.menuItem.menuName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF1F2A6D),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F2A6D).withOpacity(0.1), Color(0xFF2E3A8C).withOpacity(0.05)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0.0, 0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildContentForMenu(selectedMenu),
              ),
            ),
            _buildFooterMenu(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContentForMenu(String menu) {
    if (menu == 'Skill') {
      return FutureBuilder<List<dynamic>>(
        future: _getSkills(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading skills: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            allSkills = snapshot.data!;
            final skills = List.from(allSkills);
            skills.sort((a, b) => (a['title'] ?? '').compareTo(b['title'] ?? ''));
            final filteredSkills = skills.where((skill) {
              final title = skill['title']?.toString().toLowerCase() ?? '';
              final description = skill['description']?.toString().toLowerCase() ?? '';
              final query = _searchQuery.toLowerCase();
              final dept = skill['department']?.toString() ?? '';
              final cat = skill['category']?.toString() ?? '';
              final subCat = skill['sub_category']?.toString() ?? '';
              final prof = skill['proficiency_level']?.toString() ?? '';
              final matchesSearch = title.contains(query) || description.contains(query);
              final matchesDept = selectedDepartments.isEmpty || selectedDepartments.contains(dept);
              final matchesCat = selectedCategories.isEmpty || selectedCategories.contains(cat);
              final matchesSubCat = selectedSubCategories.isEmpty || selectedSubCategories.contains(subCat);
              final matchesProf = selectedProficiencyLevels.isEmpty || selectedProficiencyLevels.contains(prof);
              return matchesSearch && matchesDept && matchesCat && matchesSubCat && matchesProf;
            }).toList();
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search skill',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF1F2A6D)),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.filter_list, color: Color(0xFF1F2A6D)),
                        onPressed: () => _showFilterDialog(context),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF1F2A6D), width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF1F2A6D), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFFFF6A00), width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      _debounceTimer?.cancel();
                      _debounceTimer = Timer(Duration(milliseconds: 500), () {
                        setState(() {
                          _searchQuery = value;
                        });
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredSkills.length,
                    itemBuilder: (context, index) {
                      return _buildSkillCard(context, filteredSkills[index]);
                    },
                  ),
                ),
              ],
            );
          } else {
            return Center(child: Text('No skills found'));
          }
        },
      );
    }
    if (menu == 'Job Role') {
      return FutureBuilder<List<JobRole>>(
        future: _getJobRoles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading job roles: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            allJobRoles = snapshot.data!;
            final jobRoles = List.from(allJobRoles);
            jobRoles.sort((a, b) => a.jobrole.compareTo(b.jobrole));
            final filteredJobRoles = jobRoles.where((jobRole) {
              final jobrole = jobRole.jobrole.toLowerCase();
              final department = jobRole.department.toLowerCase();
              final description = (jobRole.description ?? '').toLowerCase();
              final query = _searchQuery.toLowerCase();
              final matchesSearch = jobrole.contains(query) || department.contains(query) || description.contains(query);
              final matchesDept = selectedDepartments.isEmpty || selectedDepartments.contains(jobRole.department);
              return matchesSearch && matchesDept;
            }).toList();
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search job roles',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF1F2A6D)),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.filter_list, color: Color(0xFF1F2A6D)),
                        onPressed: () => _showFilterDialog(context),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF1F2A6D), width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF1F2A6D), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFFFF6A00), width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      _debounceTimer?.cancel();
                      _debounceTimer = Timer(Duration(milliseconds: 500), () {
                        setState(() {
                          _searchQuery = value;
                        });
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredJobRoles.length,
                    itemBuilder: (context, index) {
                      return _buildJobRoleCard(context, filteredJobRoles[index]);
                    },
                  ),
                ),
              ],
            );
          } else {
            return Center(child: Text('No job roles found'));
          }
        },
      );
    }
    if (menu == 'Knowledge') {
      return FutureBuilder<List<UserKnowledge>>(
        future: _getUserKnowledge(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading knowledge: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            allKnowledge = snapshot.data!;
            final filteredKnowledge = allKnowledge.where((k) {
              final title = k.title?.toLowerCase() ?? '';
              final description = k.description?.toLowerCase() ?? '';
              final category = k.category ?? '';
              final subCategory = k.subCategory ?? '';
              final query = _searchQuery.toLowerCase();
              final matchesSearch = title.contains(query) || description.contains(query);
              final matchesCategory = selectedKnowledgeCategories.isEmpty || selectedKnowledgeCategories.contains(category);
              final matchesSubCategory = selectedKnowledgeSubCategories.isEmpty || selectedKnowledgeSubCategories.contains(subCategory);
              return matchesSearch && matchesCategory && matchesSubCategory;
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search knowledge',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF1F2A6D)),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.filter_list, color: Color(0xFF1F2A6D)),
                        onPressed: () => _showKnowledgeFilterDialog(context),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF1F2A6D), width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF1F2A6D), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFFFF6A00), width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      _debounceTimer?.cancel();
                      _debounceTimer = Timer(Duration(milliseconds: 500), () {
                        setState(() {
                          _searchQuery = value;
                        });
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredKnowledge.length,
                    itemBuilder: (context, index) {
                      return _buildKnowledgeCard(context, filteredKnowledge[index]);
                    },
                  ),
                ),
              ],
            );
          } else {
            return Center(child: Text('No knowledge found'));
          }
        },
      );
    }
    if (menu == 'Ability') {
      return FutureBuilder<List<UserAbility>>(
        future: _getUserAbility(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading abilities: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            allAbilities = snapshot.data!;
            final filteredAbilities = allAbilities.where((a) {
              final title = a.title?.toLowerCase() ?? '';
              final description = a.description?.toLowerCase() ?? '';
              final category = a.category ?? '';
              final subCategory = a.subCategory ?? '';
              final query = _searchQuery.toLowerCase();
              final matchesSearch = title.contains(query) || description.contains(query);
              final matchesCategory = selectedAbilityCategories.isEmpty || selectedAbilityCategories.contains(category);
              final matchesSubCategory = selectedAbilitySubCategories.isEmpty || selectedAbilitySubCategories.contains(subCategory);
              return matchesSearch && matchesCategory && matchesSubCategory;
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search abilities',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF1F2A6D)),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.filter_list, color: Color(0xFF1F2A6D)),
                        onPressed: () => _showAbilityFilterDialog(context),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF1F2A6D), width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF1F2A6D), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFFFF6A00), width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      _debounceTimer?.cancel();
                      _debounceTimer = Timer(Duration(milliseconds: 500), () {
                        setState(() {
                          _searchQuery = value;
                        });
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredAbilities.length,
                    itemBuilder: (context, index) {
                      return _buildAbilityCard(context, filteredAbilities[index]);
                    },
                  ),
                ),
              ],
            );
          } else {
            return Center(child: Text('No abilities found'));
          }
        },
      );
    }
    if (menu == 'Behaviour') {
      return FutureBuilder<List<UserBehaviour>>(
        future: _getUserBehaviour(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading behaviours: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            allBehaviours = snapshot.data!;
            final filteredBehaviours = allBehaviours.where((b) {
              final title = b.title?.toLowerCase() ?? '';
              final description = b.description?.toLowerCase() ?? '';
              final category = b.category ?? '';
              final subCategory = b.subCategory ?? '';
              final query = _searchQuery.toLowerCase();
              final matchesSearch = title.contains(query) || description.contains(query);
              final matchesCategory = selectedBehaviourCategories.isEmpty || selectedBehaviourCategories.contains(category);
              final matchesSubCategory = selectedBehaviourSubCategories.isEmpty || selectedBehaviourSubCategories.contains(subCategory);
              return matchesSearch && matchesCategory && matchesSubCategory;
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search behaviours',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF1F2A6D)),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.filter_list, color: Color(0xFF1F2A6D)),
                        onPressed: () => _showBehaviourFilterDialog(context),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF1F2A6D), width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF1F2A6D), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFFFF6A00), width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      _debounceTimer?.cancel();
                      _debounceTimer = Timer(Duration(milliseconds: 500), () {
                        setState(() {
                          _searchQuery = value;
                        });
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredBehaviours.length,
                    itemBuilder: (context, index) {
                      return _buildBehaviourCard(context, filteredBehaviours[index]);
                    },
                  ),
                ),
              ],
            );
          } else {
            return Center(child: Text('No behaviours found'));
          }
        },
      );
    }
    if (menu == 'Attitude') {
      return FutureBuilder<List<UserAttitude>>(
        future: _getUserAttitude(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading attitudes: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            allAttitudes = snapshot.data!;
            final filteredAttitudes = allAttitudes.where((a) {
              final title = a.title?.toLowerCase() ?? '';
              final description = a.description?.toLowerCase() ?? '';
              final category = a.category ?? '';
              final subCategory = a.subCategory ?? '';
              final query = _searchQuery.toLowerCase();
              final matchesSearch = title.contains(query) || description.contains(query);
              return matchesSearch;
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search attitudes',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF1F2A6D)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF1F2A6D), width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF1F2A6D), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFFFF6A00), width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      _debounceTimer?.cancel();
                      _debounceTimer = Timer(Duration(milliseconds: 500), () {
                        setState(() {
                          _searchQuery = value;
                        });
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredAttitudes.length,
                    itemBuilder: (context, index) {
                      return _buildAttitudeCard(context, filteredAttitudes[index]);
                    },
                  ),
                ),
              ],
            );
          } else {
            return Center(child: Text('No attitudes found'));
          }
        },
      );
    }
    return Container(
      child: Center(
        child: Text('Content for $menu will be displayed here.'),
      ),
    );
  }

  Widget _buildJobRoleCard(BuildContext context, JobRole jobRole) {
    return InkWell(
      onTap: () {
        // Show job role details
        _showJobRoleDetails(context, jobRole);
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF8F9FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.work, color: Color(0xFFFF6A00), size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      jobRole.jobrole,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2A6D),
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Color(0xFF1F2A6D), size: 16),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Department: ${jobRole.department}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Industry: ${jobRole.industries}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              if (jobRole.description != null && jobRole.description!.isNotEmpty)
                SizedBox(height: 8),
              if (jobRole.description != null && jobRole.description!.isNotEmpty)
                Text(
                  jobRole.description!.length > 100
                      ? '${jobRole.description!.substring(0, 100)}...'
                      : jobRole.description!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillCard(BuildContext context, dynamic skill) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SkillDetailScreen(
              skillId: skill['id'],
              skillTitle: skill['title'] ?? 'Skill Details',
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF8F9FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.build, color: Color(0xFFFF6A00), size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      skill['title'] ?? 'No Title',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2A6D),
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Color(0xFF1F2A6D), size: 16),
                ],
              ),
              SizedBox(height: 8),
              Text(
                skill['description'] ?? 'No Description',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildChip('Category: ${skill['category'] ?? ''}'),
                  SizedBox(width: 8),
                  _buildChip('Level: ${skill['proficiency_level'] ?? ''}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKnowledgeCard(BuildContext context, UserKnowledge knowledge) {
    return InkWell(
      onTap: () {
        _showKnowledgeDetails(context, knowledge);
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF8F9FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school, color: Color(0xFFFF6A00), size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      knowledge.title ?? 'No Title',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2A6D),
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Color(0xFF1F2A6D), size: 16),
                ],
              ),
              SizedBox(height: 8),
              Text(
                knowledge.description ?? 'No Description',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  if (knowledge.category != null)
                    _buildChip('Category: ${knowledge.category}'),
                  if (knowledge.complexityLevel != null) ...[
                    if (knowledge.category != null) SizedBox(width: 8),
                    _buildChip('Level: ${knowledge.complexityLevel}'),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbilityCard(BuildContext context, UserAbility ability) {
    return InkWell(
      onTap: () {
        _showAbilityDetails(context, ability);
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF8F9FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.accessibility, color: Color(0xFFFF6A00), size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ability.title ?? 'No Title',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2A6D),
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Color(0xFF1F2A6D), size: 16),
                ],
              ),
              SizedBox(height: 8),
              Text(
                ability.description ?? 'No Description',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  if (ability.category != null)
                    _buildChip('Category: ${ability.category}'),
                  if (ability.importanceLevel != null) ...[
                    if (ability.category != null) SizedBox(width: 8),
                    _buildChip('Level: ${ability.importanceLevel}'),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBehaviourCard(BuildContext context, UserBehaviour behaviour) {
    return InkWell(
      onTap: () {
        _showBehaviourDetails(context, behaviour);
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF8F9FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: Color(0xFFFF6A00), size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      behaviour.title ?? 'No Title',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2A6D),
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Color(0xFF1F2A6D), size: 16),
                ],
              ),
              SizedBox(height: 8),
              Text(
                behaviour.description ?? 'No Description',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  if (behaviour.category != null)
                    _buildChip('Category: ${behaviour.category}'),
                  if (behaviour.subCategory != null) ...[
                    if (behaviour.category != null) SizedBox(width: 8),
                    _buildChip('Sub: ${behaviour.subCategory}'),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttitudeCard(BuildContext context, UserAttitude attitude) {
    return InkWell(
      onTap: () {
        _showAttitudeDetails(context, attitude);
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF8F9FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.mood, color: Color(0xFFFF6A00), size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      attitude.title ?? 'No Title',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2A6D),
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Color(0xFF1F2A6D), size: 16),
                ],
              ),
              SizedBox(height: 8),
              Text(
                attitude.description ?? 'No Description',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  if (attitude.category != null)
                    _buildChip('Category: ${attitude.category}'),
                  if (attitude.subCategory != null) ...[
                    if (attitude.category != null) SizedBox(width: 8),
                    _buildChip('Sub: ${attitude.subCategory}'),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(0xFFFF6A00).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFFF6A00).withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: Color(0xFFFF6A00),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showJobRoleDetails(BuildContext context, JobRole jobRole) {
    debugPrint('Navigating to job role details screen for: ${jobRole.jobrole}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobRoleDetailScreen(jobRole: jobRole),
      ),
    );
  }

  void _showKnowledgeDetails(BuildContext context, UserKnowledge knowledge) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KnowledgeDetailScreen(knowledge: knowledge),
      ),
    );
  }

  void _showAbilityDetails(BuildContext context, UserAbility ability) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AbilityDetailScreen(ability: ability),
      ),
    );
  }

  void _showBehaviourDetails(BuildContext context, UserBehaviour behaviour) {
    // For now, show a simple dialog with behaviour details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(behaviour.title ?? 'Behaviour Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (behaviour.description != null) ...[
                Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(behaviour.description!),
                SizedBox(height: 16),
              ],
              if (behaviour.category != null) ...[
                Text('Category: ${behaviour.category}'),
                SizedBox(height: 8),
              ],
              if (behaviour.subCategory != null) ...[
                Text('Sub-Category: ${behaviour.subCategory}'),
                SizedBox(height: 8),
              ],
              if (behaviour.businessLink != null) ...[
                Text('Business Link: ${behaviour.businessLink}'),
                SizedBox(height: 8),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAttitudeDetails(BuildContext context, UserAttitude attitude) {
    // For now, show a simple dialog with attitude details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(attitude.title ?? 'Attitude Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (attitude.description != null) ...[
                Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(attitude.description!),
                SizedBox(height: 16),
              ],
              if (attitude.category != null) ...[
                Text('Category: ${attitude.category}'),
                SizedBox(height: 8),
              ],
              if (attitude.subCategory != null) ...[
                Text('Sub-Category: ${attitude.subCategory}'),
                SizedBox(height: 8),
              ],
              if (attitude.businessLink != null) ...[
                Text('Business Link: ${attitude.businessLink}'),
                SizedBox(height: 8),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6A00),
            ),
          ),
          SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildFooterMenu(BuildContext context) {
    List<Map<String, dynamic>> menuItems = [
      {'title': 'Skill', 'icon': Icons.build},
      {'title': 'Job Role', 'icon': Icons.work},
      {'title': 'Job Role Task', 'icon': Icons.task},
      {'title': 'Knowledge', 'icon': Icons.school},
      {'title': 'Ability', 'icon': Icons.accessibility},
      {'title': 'Behaviour', 'icon': Icons.people},
      {'title': 'Attitude', 'icon': Icons.mood},
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: menuItems.map((item) => _buildFooterMenuItem(context, item['title'] as String, item['icon'] as IconData)).toList(),
        ),
      ),
    );
  }

  Widget _buildFooterMenuItem(BuildContext context, String title, IconData icon) {
    bool isSelected = selectedMenu == title;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          double scale = isSelected ? 1.0 + (0.1 * value) : 1.0 - (0.05 * (1 - value));
          Color bgColor = Color.lerp(Color(0xFF1F2A6D), Color(0xFFFF6A00), isSelected ? value : 1 - value)!;
          double elevation = isSelected ? 4 + (4 * value) : 4 - (2 * (1 - value));

          return Transform.scale(
            scale: scale,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                if (title == 'Job Role Task') {
                  debugPrint('Job Role Task clicked - navigating to task screen');
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  final user = auth.currentUser;
                  debugPrint('Current user orgType: ${user?.orgType ?? "No orgType"}');
                  debugPrint('User sub institute id: ${user?.subInstituteId}');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobRoleTaskScreen(sector: user?.orgType ?? 'Healthcare'),
                    ),
                  );
                } else if (title == 'Attitude') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttitudeScreen(),
                    ),
                  );
                } else {
                  setState(() {
                    selectedMenu = title;
                  });
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [Color(0xFFFF6A00), Color(0xFFFF7A1A)]
                        : [Color(0xFF1F2A6D), Color(0xFF2E3A8C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                  boxShadow: [
                    BoxShadow(
                      color: bgColor.withOpacity(0.4),
                      blurRadius: elevation,
                      offset: Offset(0, elevation / 2),
                    ),
                    if (isSelected)
                      BoxShadow(
                        color: Color(0xFFFF6A00).withOpacity(0.6),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForMenu(String menu) {
    switch (menu) {
      case 'Skill':
        return Icons.build;
      case 'Job Role':
        return Icons.work;
      case 'Job Role Task':
        return Icons.task;
      case 'Knowledge':
        return Icons.school;
      case 'Ability':
        return Icons.accessibility;
      case 'Behaviour':
        return Icons.people;
      case 'Attitude':
        return Icons.mood;
      default:
        return Icons.apps;
    }
  }

  String _getDescriptionForMenu(String menu) {
    switch (menu) {
      case 'Skill':
        return 'Explore technical and soft skills required for various roles.';
      case 'Job Role':
        return 'View detailed descriptions of different job positions.';
      case 'Job Role Task':
        return 'Understand the specific tasks associated with job roles.';
      case 'Knowledge':
        return 'Access knowledge bases and learning resources.';
      case 'Ability':
        return 'Discover abilities and competencies needed for success.';
      case 'Behaviour':
        return 'Learn about behavioral expectations in the workplace.';
      case 'Attitude':
        return 'Understand the attitudes that drive performance.';
      default:
        return 'Content for $menu will be displayed here.';
    }
  }
}


