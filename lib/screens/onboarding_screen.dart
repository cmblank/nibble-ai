import '../config/app_colors.dart';
import 'package:flutter/material.dart';
import '../utils/profile_storage.dart';
import '../widgets/primary_button.dart';
import '../widgets/tertiary_button.dart';
import '../widgets/select_card.dart';
import '../widgets/stepper_header.dart';
import '../widgets/multi_select_pills.dart';
import '../widgets/days_per_week_slider_card.dart';

class CookingProfileOnboarding extends StatefulWidget {
  final VoidCallback onFinish;
  final Map<String, dynamic>? initialData;

  const CookingProfileOnboarding({
    super.key,
    required this.onFinish,
    this.initialData,
  });

  @override
  State<CookingProfileOnboarding> createState() => _CookingProfileOnboardingState();
}

class _CookingProfileOnboardingState extends State<CookingProfileOnboarding> {
  int currentStep = 0;
  final ScrollController _scrollController = ScrollController();
  
  // Profile data
  String userName = '';
  String selectedExperience = '';
  List<String> selectedDiets = [];
  List<String> selectedAllergies = [];
  List<String> selectedCuisines = [];
  String selectedCookingTime = '';
  String selectedBudget = '';
  // Step 2: Tools & Skills
  List<String> selectedTools = [];

  // Step 1: Kitchen Life
  int cookNightsCurrent = 0; // 0-7
  int cookNightsGoal = 0; // 0-7
  String household = '';
  String firstGoal = '';
  List<String> mealFocus = [];
  List<String> cookMotivations = [];
  List<String> cookBlockers = [];

  // Hover tracking (desktop)
  // (hover state managed within widgets as needed)

  // Step 2 options (title - description)
  final List<String> experienceLevels = const [
    "Beginner - I'm just starting my cooking journey!",
    'Comfortable - I can follow recipes confidently',
    'Confident Chef - I love experimenting in the kitchen',
  ];

  final List<String> toolOptions = const [
    'Air fryer',
    'Slow cooker',
    'Grill',
    'Blender',
    'Pressure cooker',
    'Hand mixer',
    'Microwave',
    'None',
  ];

  final List<String> dietaryPreferences = [
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Keto',
    'Paleo',
    'Mediterranean',
    'Low-carb',
    'No restrictions'
  ];

  final List<String> commonAllergies = [
    'Nuts',
    'Dairy',
    'Gluten',
    'Shellfish',
    'Eggs',
    'Soy',
    'Fish',
    'None'
  ];

  final List<String> cuisineTypes = [
    'Italian',
    'Mexican',
    'Asian',
    'Mediterranean',
    'American',
    'Indian',
    'French',
    'Thai'
  ];

  final List<String> cookingTimes = [
    '15 minutes or less',
    '15-30 minutes',
    '30-60 minutes',
    'Over 1 hour',
    'I have all day!'
  ];

  final List<String> budgetRanges = [
    'Very budget-friendly (\$)',
    'Moderate (\$\$)',
    'Higher-end (\$\$\$)',
    'No budget concerns'
  ];

  // Options for Step 1 UI
  final List<String> householdOptions = const [
    'Just me',
    'Me & my partner',
    'Small family (3-4)',
    'Big family / group (5+)',
    'Roommates / shared kitchen',
    'Kids part-time',
  ];

  final List<Map<String, String>> firstCookingGoals = const [
    {
      'title': 'Cut back on takeout',
      'desc': "Swap delivery nights for quick, satisfying dinners you'll actually look forward to.",
    },
    {
      'title': 'Add more vegetables',
      'desc': 'Bring more greens and color to your plate without extra hassle.',
    },
    {
      'title': 'Use what I have',
      'desc': "Turn what's in your kitchen into dinners you'll be proud of.",
    },
    {
      'title': 'Make cooking feel easier',
      'desc': "Simple recipes now, skills you'll grow over time.",
    },
  ];

  final List<String> mealFocusOptions = const [
    '30-minute meals',
    'Slow cooker',
    'One pan meals',
    'Grill & BBQ meals',
    'Batch cook / meal prep',
    'Small bites',
    'Healthy snacks',
    'Quick lunches',
    'Light & fresh',
    'Comfort food',
    'Kid friendly',
    'Special occasions',
  ];

  final List<String> motivationOptions = const [
    'Eat healthier',
    'Enjoy cooking more',
    'Save money',
    'Manage blood sugar',
    'Reduce takeout',
    'Learn new recipes',
    'Other',
  ];

  final List<String> blockerOptions = const [
    'No time',
    'low energy',
    "Don't know what to make",
    'Hate grocery shopping',
    'Lack of confidence',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _loadInitialData() {
    final data = widget.initialData!;
    userName = data['name'] ?? '';
    selectedExperience = data['experience'] ?? '';
    selectedDiets = List<String>.from(data['diets'] ?? []);
    selectedAllergies = List<String>.from(data['allergies'] ?? []);
    selectedCuisines = List<String>.from(data['cuisines'] ?? []);
    selectedCookingTime = data['cookingTime'] ?? '';
    selectedBudget = data['budget'] ?? '';
  }

  void _nextStep() {
    setState(() {
      currentStep = (currentStep + 1).clamp(0, 6);
    });
  _scrollToTop();
  }

  void _previousStep() {
    setState(() {
      currentStep = (currentStep - 1).clamp(0, 6);
    });
  _scrollToTop();
  }

  @override
  Widget build(BuildContext context) {
    if (currentStep == 0) return _buildWelcomeScreen();
    if (currentStep == 1) return _buildKitchenLifeStep();
    if (currentStep == 2) return _buildToolsSkillsStep();
    if (currentStep == 3) return _buildFoodPreferencesStep();
    if (currentStep == 4) return _buildPantrySnapshotStep();
    if (currentStep == 5) return _buildStayingInSyncStep();
    if (currentStep == 6) return _buildCompletionScreen();
    return const SizedBox.shrink();
  }

  Widget _buildWelcomeScreen() {
    return Scaffold(
      backgroundColor: AppColors.gardenHerb,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/nib-welcome.png',
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Welcome to Nibble',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Let’s set you up with a plan that fits your taste, schedule, and kitchen. It only takes a couple minutes, and you can update it anytime.",
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        height: 1.5,
                        color: Color(0xFF374151),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: "Let's get started",
                      onPressed: _nextStep,
                      fullWidth: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TertiaryButton(
                        label: 'Skip for now',
                        onPressed: _saveAndFinish,
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
  }

  // Step 1: Kitchen life
  Widget _buildKitchenLifeStep() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepperHeader(
                step: 1,
                totalSteps: 5,
                title: 'Kitchen Life',
                subtitle: 'Helps Nibble understand your cooking needs and goals',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('On most weeks, how many nights do you end up cooking at home?'),
                    DaysPerWeekSliderCard(
                      value: cookNightsCurrent,
                      onChanged: (v) => setState(() => cookNightsCurrent = v),
                    ),
                    _sectionRule(),
                    _sectionTitle('Over time, how many nights would you love Nibble to help you cook'),
                    DaysPerWeekSliderCard(
                      value: cookNightsGoal,
                      onChanged: (v) => setState(() => cookNightsGoal = v),
                    ),
                    _sectionRule(),
                    _sectionTitle('Who’s usually around your table?'),
                    const SizedBox(height: 16),
                    ...householdOptions
                        .asMap()
                        .entries
                        .map((entry) {
                      final idx = entry.key;
                      final opt = entry.value;
                      final isLast = idx == householdOptions.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 12.0),
                        child: SelectCard(
                          title: opt,
                          description: '',
                          showDescription: false,
                          selected: household == opt,
                          onTap: () => setState(() => household = opt),
                        ),
                      );
                    }),
                    _sectionRule(),
                    _sectionTitle('Your first cooking goal'),
                    const SizedBox(height: 16),
                    ...firstCookingGoals
                        .asMap()
                        .entries
                        .map((entry) {
                      final idx = entry.key;
                      final g = entry.value;
                      final isLast = idx == firstCookingGoals.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 12.0),
                        child: SelectCard(
                          title: g['title']!,
                          description: g['desc']!,
                          selected: firstGoal == g['title'],
                          onTap: () => setState(() => firstGoal = g['title']!),
                        ),
                      );
                    }),
                    _sectionRule(),
                    _sectionTitle('What kinds of meals should I focus on for you?'),
                    const SizedBox(height: 16),
                    MultiSelectPills(
                      options: mealFocusOptions,
                      selectedOptions: mealFocus,
                      onSelectionChanged: (val) {
                        setState(() {
                          if (mealFocus.contains(val)) {
                            mealFocus.remove(val);
                          } else {
                            mealFocus.add(val);
                          }
                        });
                      },
                    ),
                    _sectionRule(),
                    _sectionTitle('What’s driving you to cook more?'),
                    const SizedBox(height: 16),
                    MultiSelectPills(
                      options: motivationOptions,
                      selectedOptions: cookMotivations,
                      onSelectionChanged: (val) {
                        setState(() {
                          if (cookMotivations.contains(val)) {
                            cookMotivations.remove(val);
                          } else {
                            cookMotivations.add(val);
                          }
                        });
                      },
                    ),
                    _sectionRule(),
                    _sectionTitle('What sometimes gets in the way of cooking?'),
                    const SizedBox(height: 16),
                    MultiSelectPills(
                      options: blockerOptions,
                      selectedOptions: cookBlockers,
                      onSelectionChanged: (val) {
                        setState(() {
                          if (cookBlockers.contains(val)) {
                            cookBlockers.remove(val);
                          } else {
                            cookBlockers.add(val);
                          }
                        });
                      },
                    ),
                    _sectionRule(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TertiaryButton(
                          label: 'Back',
                          onPressed: _previousStep,
                        ),
                        PrimaryButton(
                          label: 'Continue',
                          onPressed: _nextStep,
                          fullWidth: false,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          fontSize: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Step 2: Tools & Skills
  Widget _buildToolsSkillsStep() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepperHeader(
                step: 2,
                totalSteps: 5,
                title: 'Tools & Skills',
                subtitle: 'Helps Nibble match recipes to your skills and tools.',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('How would you describe your kitchen comfort level?'),
                    const SizedBox(height: 16),
                    ...experienceLevels.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final level = entry.value;
                      final isLast = idx == experienceLevels.length - 1;
                      final parts = level.split(' - ');
                      final title = parts.isNotEmpty ? parts.first : level;
                      final description = parts.length > 1 ? parts.sublist(1).join(' - ') : '';
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 12.0),
                        child: SelectCard(
                          title: title,
                          description: description,
                          selected: selectedExperience == level,
                          onTap: () => setState(() => selectedExperience = level),
                        ),
                      );
                    }),
                    _sectionRule(),
                    _sectionTitle('Which of these tools do you already have?'),
                    const SizedBox(height: 16),
                    MultiSelectPills(
                      options: toolOptions,
                      selectedOptions: selectedTools,
                      onSelectionChanged: (tool) {
                        setState(() {
                          if (tool == 'None') {
                            // Selecting None clears others; selecting others removes None
                            selectedTools = selectedTools.contains('None')
                                ? []
                                : ['None'];
                          } else {
                            selectedTools.remove('None');
                            if (selectedTools.contains(tool)) {
                              selectedTools.remove(tool);
                            } else {
                              selectedTools.add(tool);
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TertiaryButton(label: 'Back', onPressed: _previousStep),
                        PrimaryButton(
                          label: 'Continue',
                          onPressed: _nextStep,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          fontSize: 16,
                          fullWidth: false,
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Step 3: Food Preferences
  Widget _buildFoodPreferencesStep() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepperHeader(
                step: 3,
                totalSteps: 5,
                title: 'Food Preferences',
                subtitle: 'Set the guardrails for great recommendations',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Any dietary preferences?'),
                    const SizedBox(height: 16),
                    MultiSelectPills(
                      options: dietaryPreferences,
                      selectedOptions: selectedDiets,
                      onSelectionChanged: (diet) {
                        setState(() {
                          if (selectedDiets.contains(diet)) {
                            selectedDiets.remove(diet);
                          } else {
                            selectedDiets.add(diet);
                          }
                        });
                      },
                    ),
                    _sectionRule(),
                    _sectionTitle('Any food allergies or restrictions?'),
                    const SizedBox(height: 16),
                    MultiSelectPills(
                      options: commonAllergies,
                      selectedOptions: selectedAllergies,
                      onSelectionChanged: (allergy) {
                        setState(() {
                          if (selectedAllergies.contains(allergy)) {
                            selectedAllergies.remove(allergy);
                          } else {
                            selectedAllergies.add(allergy);
                          }
                        });
                      },
                    ),
                    _sectionRule(),
                    _sectionTitle('What cuisines make you excited to cook?'),
                    const SizedBox(height: 16),
                    MultiSelectPills(
                      options: cuisineTypes,
                      selectedOptions: selectedCuisines,
                      onSelectionChanged: (cuisine) {
                        setState(() {
                          if (selectedCuisines.contains(cuisine)) {
                            selectedCuisines.remove(cuisine);
                          } else {
                            selectedCuisines.add(cuisine);
                          }
                        });
                      },
                    ),
                    _sectionRule(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TertiaryButton(label: 'Back', onPressed: _previousStep),
                        PrimaryButton(
                          label: 'Continue',
                          onPressed: _nextStep,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          fontSize: 16,
                          fullWidth: false,
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Step 4: Pantry Snapshot (temporary content reused from time preferences)
  Widget _buildPantrySnapshotStep() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepperHeader(
                step: 4,
                totalSteps: 5,
                title: 'Pantry Snapshot',
                subtitle: 'A quick sense of your routine helps planning',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('How much time do you usually have for cooking?'),
                    const SizedBox(height: 16),
                    ...cookingTimes.map((time) => _buildOptionTile(
                          time,
                          selectedCookingTime == time,
                          () => setState(() => selectedCookingTime = time),
                        )),
                    _sectionRule(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TertiaryButton(label: 'Back', onPressed: _previousStep),
                        PrimaryButton(
                          label: 'Continue',
                          onPressed: _nextStep,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          fontSize: 16,
                          fullWidth: false,
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Step 5: Staying in Sync (placeholder content)
  Widget _buildStayingInSyncStep() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepperHeader(
                step: 5,
                totalSteps: 5,
                title: 'Staying in Sync',
                subtitle: "We'll help keep plans and preferences up to date",
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "We'll add calendar integrations and reminders here soon. For now, you can finish setup and start cooking!",
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        height: 1.5,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TertiaryButton(label: 'Back', onPressed: _previousStep),
                        PrimaryButton(
                          label: 'Complete Setup',
                          onPressed: _saveAndFinish,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          fontSize: 16,
                          fullWidth: false,
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text('✨', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Wonderful, Chef ${userName.isNotEmpty ? userName : 'there'}!',
                style: const TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.w700, 
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "I've got everything I need to be your perfect cooking companion. Let's take the pressure off and focus on what feels achievable and delicious.",
                style: TextStyle(
                  fontSize: 18, 
                  height: 1.5, 
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Ready to create something amazing in your kitchen?',
                style: TextStyle(
                  fontSize: 16, 
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Start Cooking with Nibble!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helpers
  Widget _buildOptionTile(String title, bool isSelected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF059669).withOpacity(0.1) : Colors.white,
            border: Border.all(
              color: isSelected ? const Color(0xFF059669) : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF059669).withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF059669) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF059669) : const Color(0xFF9CA3AF),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? const Color(0xFF059669) : const Color(0xFF374151),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  

  Widget _sectionTitle(String title, [String? subtitle]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionRule() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFD7DBE0),
      ),
    );
  }

  Future<void> _saveAndFinish() async {
    final profileData = {
      'name': userName,
      'experience': selectedExperience,
  'tools': selectedTools,
      'diets': selectedDiets,
      'allergies': selectedAllergies,
      'cuisines': selectedCuisines,
      'cookingTime': selectedCookingTime,
      'budget': selectedBudget,
      // Step 1 fields
      'cookNightsCurrent': cookNightsCurrent,
      'cookNightsGoal': cookNightsGoal,
      'household': household,
      'firstGoal': firstGoal,
      'mealFocus': mealFocus,
      'cookMotivations': cookMotivations,
      'cookBlockers': cookBlockers,
      'completedAt': DateTime.now().toIso8601String(),
    };

    await ProfileStorage.saveProfile(profileData);
    widget.onFinish();
  }
}