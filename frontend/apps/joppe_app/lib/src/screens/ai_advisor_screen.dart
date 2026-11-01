import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Man hinh tro ly AI tam an (Dang nang cap sang he thong Backend AI tap trung)
class AiAdvisorScreen extends StatelessWidget {
  final String? initialPrompt;

  const AiAdvisorScreen({super.key, this.initialPrompt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBackground,
      appBar: AppBar(
        title: const Text('Trợ Lý AI Joppe'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.engineering_outlined, size: 64, color: AppColors.primaryBlue),
              const SizedBox(height: 16),
              const Text(
                'Tính năng đang được nâng cấp',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hệ thống AI đang được tích hợp trực tiếp với cổng Joppe AI Backend.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
