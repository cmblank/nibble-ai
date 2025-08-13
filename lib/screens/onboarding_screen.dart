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
  
  // Profile data
  String userName = '';
  String selectedExperience = '';
  List<String> selectedDiets = [];
  List<String> selectedAllergies = [];
  List<String> selectedCuisines = [];
  String selectedCookingTime = '';
  String selectedBudget = '';

  // Step 1: Kitchen Life & Motivation (from Figma)
  int cookNightsCurrent = 0; // 0-7
  int cookNightsGoal = 0; // 0-7
  String household = '';
  String firstGoal = '';
  List<String> mealFocus = [];
  List<String> cookMotivations = [];
  List<String> cookBlockers = [];

  // Hover tracking (desktop): use same styling as selected when hovered
  String? _hoveredHousehold;
  String? _hoveredGoal;
  final Set<String> _hoveredChipOptions = {};

  final List<String> experienceLevels = [
    'Beginner - I\'m just starting my cooking journey!',
    'Intermediate - I can follow recipes confidently',
    'Advanced - I love experimenting in the kitchen',
    'Expert - I could teach others to cook'
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
      'desc': 'Swap delivery nights for quick, satisfying dinners you\'ll actually look forward to.',
    },
    {
      'title': 'Add more vegetables',
      'desc': 'Bring more greens and color to your plate without extra hassle.',
    },
    {
      'title': 'Use what I have',
      'desc': 'Turn what\'s in your kitchen into dinners you\'ll be proud of.',
    },
    {
      'title': 'Make cooking feel easier',
      'desc': 'Simple recipes now, skills you\'ll grow over time.',
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
    'Don\'t know what to make',
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
    if (currentStep < 7) {
      setState(() {
        currentStep++;
      });
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentStep == 0) {
      return _buildWelcomeScreen();
    } else if (currentStep == 1) {
      return _buildNameScreen();
    } else if (currentStep == 8) {
      return _buildCompletionScreen();
    }
    
    return Scaffold(
      backgroundColor: AppColors.creamWhisk,
      appBar: AppBar(
  backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.deepRoast),
          onPressed: _previousStep,
        ),
        actions: [
          TextButton(
            onPressed: _saveAndFinish,
            child: const Text(
              'Skip',
              style: TextStyle(color: AppColors.gardenHerb),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: currentStep / 8,
              minHeight: 6,
              backgroundColor: AppColors.goldenCrust,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gardenHerb),
            ),
            const SizedBox(height: 32),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: _buildCurrentStepContent(),
              ),
            ),
            
            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TertiaryButton(
                  label: 'Back',
                  onPressed: currentStep > 1 ? _previousStep : null,
                  filled: true,
                ),
        ElevatedButton(
                  onPressed: _canProceed() ? (currentStep == 7 ? _saveAndFinish : _nextStep) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gardenHerb,
                    foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(currentStep == 7 ? 'Complete Setup' : 'Continue'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
                    // Figma illustration (mascot + speech bubble)
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
                        fontWeight: FontWeight.w700, // Bold per request
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

  Widget _buildNameScreen() {
    // Step 1: Kitchen Life & Motivation
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepperHeader(
                step: 1,
                totalSteps: 8,
                title: 'Your Kitchen Life & Motivation',
                subtitle: 'Helps nibble understand your cooking needs and goals',
              ),
              // Page content with padding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // Sliders section
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
                      // Navigation
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
                'I\'ve got everything I need to be your perfect cooking companion. Let\'s take the pressure off and focus on what feels achievable and delicious.',
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

  Widget _buildCurrentStepContent() {
    switch (currentStep) {
      case 2:
        return _buildExperienceStep();
      case 3:
        return _buildDietStep();
      case 4:
        return _buildAllergiesStep();
      case 5:
        return _buildCuisinesStep();
      case 6:
        return _buildTimeStep();
      case 7:
        return _buildBudgetStep();
      default:
        return Container();
    }
  }

  bool _canProceed() {
    switch (currentStep) {
      case 1:
  // Don\'t block on this multi-section screen; all fields are optional
  return true;
      case 2:
        return selectedExperience.isNotEmpty;
      case 3:
        return selectedDiets.isNotEmpty;
      case 4:
        return selectedAllergies.isNotEmpty;
      case 5:
        return selectedCuisines.isNotEmpty;
      case 6:
        return selectedCookingTime.isNotEmpty;
      case 7:
        return selectedBudget.isNotEmpty;
      default:
        return true;
    }
  }

  Widget _buildExperienceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepperHeader(
          step: 2,
          totalSteps: 8,
          title: "What's your cooking experience level?",
          subtitle: 'This helps me suggest recipes that match your skill level and comfort zone.',
        ),
        const SizedBox(height: 24),
        ...experienceLevels.map((level) {
          final parts = level.split(' - ');
          final title = parts.isNotEmpty ? parts.first : level;
          final description = parts.length > 1 ? parts.sublist(1).join(' - ') : '';
          final isSelected = selectedExperience == level;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: SelectCard(
              title: title,
              description: description,
              selected: isSelected,
              onTap: () => setState(() => selectedExperience = level),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDietStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepperHeader(
          step: 3,
          totalSteps: 8,
          title: 'Any dietary preferences?',
          subtitle: 'Select all that apply so I can tailor your recipe suggestions perfectly.',
        ),
        const SizedBox(height: 32),
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
      ],
    );
  }

  Widget _buildAllergiesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepperHeader(
          step: 4,
          totalSteps: 8,
          title: 'Any food allergies or restrictions?',
          subtitle: "I'll make sure to keep these completely out of your recommendations for safe cooking.",
        ),
        const SizedBox(height: 32),
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
      ],
    );
  }

  Widget _buildCuisinesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepperHeader(
          step: 5,
          totalSteps: 8,
          title: 'What cuisines make you excited to cook?',
          subtitle: "Choose your favorites so I can fill your feed with flavors you'll love exploring.",
        ),
        const SizedBox(height: 32),
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
      ],
    );
  }

  Widget _buildTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepperHeader(
          step: 6,
          totalSteps: 8,
          title: 'How much time do you usually have for cooking?',
          subtitle: "I'll prioritize recipes that fit comfortably into your schedule without stress.",
        ),
        const SizedBox(height: 32),
        ...cookingTimes.map((time) => _buildOptionTile(
              time,
              selectedCookingTime == time,
              () => setState(() => selectedCookingTime = time),
            )),
      ],
    );
  }

  Widget _buildBudgetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepperHeader(
          step: 7,
          totalSteps: 8,
          title: "What's your typical grocery budget?",
          subtitle: 'This helps me suggest recipes with ingredients that work for your budget and lifestyle.',
        ),
        const SizedBox(height: 32),
        ...budgetRanges.map((budget) => _buildOptionTile(
              budget,
              selectedBudget == budget,
              () => setState(() => selectedBudget = budget),
            )),
      ],
    );
  }

  // Selection tile with hover (hover uses selected styling)
  Widget _selectionTile({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final highlighted = selected || _hoveredHousehold == title;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredHousehold = title),
      onExit: (_) => setState(() {
        if (_hoveredHousehold == title) _hoveredHousehold = null;
      }),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlighted ? AppColors.gardenHerb : const Color(0xFFE5E7EB),
              width: highlighted ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Radio-style indicator
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: highlighted ? AppColors.gardenHerb : const Color(0xFF9CA3AF),
                    width: 2,
                  ),
                ),
                child: highlighted
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.gardenHerb,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
                    color: highlighted ? AppColors.gardenHerb : const Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Goal card with hover (hover uses selected styling)
  Widget _goalCard({
    required String title,
    required String desc,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final highlighted = selected || _hoveredGoal == title;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredGoal = title),
      onExit: (_) => setState(() {
        if (_hoveredGoal == title) _hoveredGoal = null;
      }),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlighted ? AppColors.gardenHerb : const Color(0xFFE5E7EB),
              width: highlighted ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Radio-style indicator
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: highlighted ? AppColors.gardenHerb : const Color(0xFF9CA3AF),
                    width: 2,
                  ),
                ),
                child: highlighted
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gardenHerb,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF6B7280),
                      ),
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

  Widget _buildMultiSelectPills({
    required List<String> options,
    required List<String> selectedOptions,
    required Function(String) onSelectionChanged,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((option) {
        final isSelected = selectedOptions.contains(option);
        final isHovered = _hoveredChipOptions.contains(option);
        final highlighted = isSelected || isHovered;
        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredChipOptions.add(option)),
          onExit: (_) => setState(() => _hoveredChipOptions.remove(option)),
          child: GestureDetector(
            onTap: () => onSelectionChanged(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: highlighted ? AppColors.gardenHerb : const Color(0xFFE5E7EB),
                  width: highlighted ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                option,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
                  color: highlighted ? AppColors.gardenHerb : const Color(0xFF374151),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _saveAndFinish() async {
    final profileData = {
      'name': userName,
      'experience': selectedExperience,
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

extension _OnboardingUiHelpers on _CookingProfileOnboardingState {
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

  // 1px horizontal rule between sections with #D7DBE0 and balanced spacing
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

  

  // Figma-spec input meter for 0–7 days/week with animated fill and step markers
  // Discrete steps, tap/drag to select nearest step, smooth width animation.
  // Visuals:
  // - Track: 6px height, rounded, bg #D9D9D9
  // - Fill: AppColors.gardenHerb, animates to selected step center, min 9px at 0
  // - Dots: 16x16 circles at each step; selected filled green, others outlined
  // - Labels: 0..7 under dots, selected dark w600, others placeholder w400
  // removed in favor of reusable widget DaysPerWeekMeter
}

// Welcome Step with Chef Mascot
class _WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomeStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Chef Squire Mascot
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                // Chef hat
                Positioned(
                  top: 15,
                  child: Text('👨‍🍳', style: TextStyle(fontSize: 40)),
                ),
                // Leaf accent
                Positioned(
                  bottom: 15,
                  right: 15,
                  child: Text('🍃', style: TextStyle(fontSize: 20)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '👋 Welcome to Nibble!',
            style: TextStyle(
              fontSize: 32, 
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cozy cooking companion is here! I\'m Chef Squire, and I\'m excited to help you cook with more joy and less stress.',
            style: TextStyle(
              fontSize: 18,
              height: 1.4,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Let\'s set up your cooking profile so I can be genuinely helpful and make your kitchen adventures feel effortless!',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Start My Cooking Journey',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Basic Info Step (simplified for now)
class _BasicInfoStep extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Map<String, dynamic> formData;
  final int step;
  const _BasicInfoStep({required this.onNext, required this.onBack, required this.formData, required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepperHeader(step: step, totalSteps: 8, title: 'Let\'s get acquainted'),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('👨‍�', style: TextStyle(fontSize: 24)),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'First things first — what should I call you, Chef?',
                    style: TextStyle(
                      fontSize: 16, 
                      height: 1.5, 
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'What should I call you?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: formData['name'] ?? '',
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
              ),
              hintText: 'Chef [Your Name]',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (val) => formData['name'] = val,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TertiaryButton(
                label: 'Back',
                onPressed: onBack,
              ),
        ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Continue Cooking Journey', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Finish Step
class _FinishStep extends StatelessWidget {
  final VoidCallback onFinish;
  final VoidCallback onBack;
  final Map<String, dynamic> formData;
  const _FinishStep({required this.onFinish, required this.onBack, required this.formData});

  @override
  Widget build(BuildContext context) {
    String userName = formData['name'] ?? 'there';
    
    return Padding(
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
            'Wonderful, Chef $userName!',
            style: const TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.w700, 
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'I\'ve got everything I need to be your perfect cooking companion. Let\'s take the pressure off and focus on what feels achievable and delicious.',
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
              onPressed: () async {
                await ProfileStorage.saveProfile(formData);
                onFinish();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Start Cooking with Nibble!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TertiaryButton(
            label: 'Back',
            onPressed: onBack,
          ),
        ],
      ),
    );
  }
}

// Stepper Header moved to lib/widgets/stepper_header.dart (Figma-spec)