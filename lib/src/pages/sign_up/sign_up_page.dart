import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/auth/sign_up_controller.dart';
import '../../routes/app_routes.dart';

class SignUpPage extends StatelessWidget {
  SignUpPage({super.key});

  // FormKey belongs to UI, NOT controller
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SignUpController());
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
                Text("Create Account", style: textTheme.displaySmall),
                const SizedBox(height: 8),
                Text("Fill your information below",
                    style: textTheme.bodyMedium),
                const SizedBox(height: 40),

                // Name
                TextFormField(
                  controller: controller.nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                  validator: (v) =>
                  v == null || v.isEmpty ? "Enter required field" : null,
                ),
                const SizedBox(height: 10),

                // Phone (digits only, max 10)
                TextFormField(
                  controller: controller.phoneController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration:
                  const InputDecoration(labelText: "Phone Number"),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Enter required field";
                    }
                    if (v.length != 10) {
                      return "Enter a valid 10-digit number";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Email
                TextFormField(
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Enter required field";
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Password
                TextFormField(
                  controller: controller.passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    suffixIcon: Icon(Icons.visibility),
                  ),
                  validator: (v) =>
                  v == null || v.isEmpty ? "Enter required field" : null,
                ),
                const SizedBox(height: 20),

                // Sign Up
                Obx(
                      () => SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () {
                        if (_formKey.currentState!.validate()) {
                          controller.sendOtp();
                        }
                      },
                      child: controller.isLoading.value
                          ? const CircularProgressIndicator(
                          color: Colors.white)
                          : const Text("Sign Up"),
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                RichText(
                  text: TextSpan(
                    style: textTheme.bodyMedium,
                    text: "Already have an account? ",
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        recognizer: TapGestureRecognizer()
                          ..onTap =
                              () => Get.toNamed(AppRoutes.signIn),
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
