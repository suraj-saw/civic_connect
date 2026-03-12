import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/sign_in_controller.dart';
import '../../../core/routes/app_routes.dart';

class SignInPage extends StatelessWidget {
  SignInPage({super.key});

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<SignInController>()
        ? Get.find<SignInController>()
        : Get.put(SignInController());

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Welcome Back', style: textTheme.displaySmall),
                const SizedBox(height: 8),
                Text('Sign in to your account', style: textTheme.bodyMedium),
                const SizedBox(height: 40),

                // Email
                TextFormField(
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password
                Obx(() => TextFormField(
                  controller: controller.passwordController,
                  obscureText: !controller.isPasswordVisible.value,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isPasswordVisible.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => controller.isPasswordVisible.toggle(),
                    ),
                  ),
                  validator: (v) =>
                  v == null || v.isEmpty ? 'Password is required' : null,
                )),
                const SizedBox(height: 30),

                // Sign In Button
                Obx(() => SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () {
                      if (_formKey.currentState!.validate()) {
                        controller.signIn();
                      }
                    },
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Sign In'),
                  ),
                )),

                const SizedBox(height: 60),

                RichText(
                  text: TextSpan(
                    style: textTheme.bodyMedium,
                    text: "Don't have an account? ",
                    children: [
                      TextSpan(
                        text: 'Sign Up',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Get.toNamed(AppRoutes.signUp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}