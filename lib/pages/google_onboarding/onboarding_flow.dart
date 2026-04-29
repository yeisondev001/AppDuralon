import 'package:flutter/material.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_data.dart';
import 'package:app_duralon/pages/google_onboarding/step_1_client_type.dart';

class OnboardingFlow extends StatelessWidget {
  const OnboardingFlow({super.key});

  @override
  Widget build(BuildContext context) {
    final data = OnboardingData();
    return Step1ClientTypeScreen(data: data);
  }
}
