import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../services/api_service.dart';
import '../providers.dart';
import 'shell.dart';
import '../utils/custom_snackbar.dart';
import 'onboarding_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

enum LoginMode { phone, alias }

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final aliasController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  LoginMode mode = LoginMode.alias;
  bool passwordVisible = false;
  String countryCode = '+90';
  bool attempted = false;

  bool get isValid {
    final passOk = passwordController.text.trim().length >= 6;
    if (mode == LoginMode.alias) {
      final aliasOk = aliasController.text.trim().length >= 3;
      return aliasOk && passOk;
    } else {
      final digits = phoneController.text.replaceAll(RegExp(r'\D'), '');
      final phoneOk =
          countryCode == '+90' ? digits.length == 10 : digits.length >= 10;
      return phoneOk && passOk;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer.withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.tertiaryContainer.withValues(alpha: 0.25),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0, end: 1),
                    builder:
                        (context, val, child) => Opacity(
                          opacity: val,
                          child: Transform.translate(
                            offset: Offset(0, (1 - val) * 16),
                            child: child,
                          ),
                        ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: Image.asset('logo.png', height: 120)),
                        const SizedBox(height: 12),
                        Text(
                          'Anonim sohbet, mükemmel deneyim.',
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: cs.onPrimary),
                        ),
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: cs.outlineVariant),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  SegmentedButton<LoginMode>(
                                    style: SegmentedButton.styleFrom(
                                      textStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    segments: const [
                                      ButtonSegment(
                                        value: LoginMode.alias,
                                        label: FittedBox(
                                          child: Text('Takma Ad'),
                                        ),
                                      ),
                                      ButtonSegment(
                                        value: LoginMode.phone,
                                        label: FittedBox(
                                          child: Text('Telefon'),
                                        ),
                                      ),
                                    ],
                                    selected: {mode},
                                    onSelectionChanged:
                                        (s) => setState(() => mode = s.first),
                                  ),
                                  const SizedBox(height: 12),
                                  if (mode == LoginMode.alias)
                                    TextField(
                                      controller: aliasController,
                                      textInputAction: TextInputAction.next,
                                      keyboardType: TextInputType.text,
                                      decoration: InputDecoration(
                                        labelText: 'Takma Ad',
                                        hintText: 'Görünen adınız',
                                        prefixIcon: const Icon(Icons.tag),
                                        errorText:
                                            attempted &&
                                                    aliasController.text
                                                            .trim()
                                                            .length <
                                                        3
                                                ? 'Takma ad gerekli'
                                                : null,
                                      ),
                                    )
                                  else
                                    TextField(
                                      controller: phoneController,
                                      textInputAction: TextInputAction.next,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'Telefon',
                                        hintText:
                                            countryCode == '+90'
                                                ? '5xx xxx xx xx'
                                                : 'Numara',
                                        prefixText: '$countryCode ',
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.expand_more),
                                          onPressed: () async {
                                            final code =
                                                await showModalBottomSheet<
                                                  String
                                                >(
                                                  context: context,
                                                  builder:
                                                      (_) => _CountryCodeSheet(
                                                        selected: countryCode,
                                                      ),
                                                );
                                            if (code != null) {
                                              setState(
                                                () => countryCode = code,
                                              );
                                            }
                                          },
                                        ),
                                        errorText:
                                            attempted &&
                                                    !(countryCode == '+90'
                                                        ? phoneController.text
                                                                .replaceAll(
                                                                  RegExp(r'\D'),
                                                                  '',
                                                                )
                                                                .length ==
                                                            10
                                                        : phoneController.text
                                                                .replaceAll(
                                                                  RegExp(r'\D'),
                                                                  '',
                                                                )
                                                                .length >=
                                                            10)
                                                ? 'Telefon numarası geçersiz'
                                                : null,
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: passwordController,
                                    obscureText: !passwordVisible,
                                    decoration: InputDecoration(
                                      labelText: 'Şifre',
                                      hintText: '••••••••',
                                      prefixIcon: const Icon(Icons.lock),
                                      errorText:
                                          attempted &&
                                                  passwordController.text
                                                          .trim()
                                                          .length <
                                                      6
                                              ? 'Yanlış şifre'
                                              : null,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          passwordVisible
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed:
                                            () => setState(
                                              () =>
                                                  passwordVisible =
                                                      !passwordVisible,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Şifremi Unuttum Butonu
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    const ForgotPasswordScreen(),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Şifremi Unuttum',
                                        style: TextStyle(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Premium Giriş Yap Butonu
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        colors: [cs.primary, cs.secondary],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: cs.primary.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap:
                                            isValid
                                                ? () async {
                                                  setState(
                                                    () => attempted = true,
                                                  );
                                                  final api = ref.read(
                                                    apiServiceProvider,
                                                  );

                                                  // Basit bir loading göstergesi ekleyelim
                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder:
                                                        (
                                                          context,
                                                        ) => const Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        ),
                                                  );

                                                  final isPhone =
                                                      mode == LoginMode.phone;
                                                  final aliasOrPhone =
                                                      isPhone
                                                          ? countryCode +
                                                              phoneController
                                                                  .text
                                                                  .replaceAll(
                                                                    RegExp(
                                                                      r'\D',
                                                                    ),
                                                                    '',
                                                                  )
                                                          : aliasController.text
                                                              .trim();
                                                  final password =
                                                      passwordController.text;

                                                  final result = await api
                                                      .login(
                                                        aliasOrPhone:
                                                            aliasOrPhone,
                                                        password: password,
                                                        isPhone: isPhone,
                                                      );

                                                  if (!context.mounted) {
                                                    return;
                                                  }

                                                  Navigator.pop(
                                                    context,
                                                  ); // Loading dialogunu kapat

                                                  if (result['success']) {
                                                    ref.invalidate(
                                                      userProfileProvider,
                                                    );

                                                    // Kullanıcının silinip silinmediğini kontrol etmek için profil bilgisini çekiyoruz
                                                    final profileResult =
                                                        await api.getProfile();

                                                    if (!context.mounted) {
                                                      return;
                                                    }

                                                    if (profileResult['success'] ==
                                                        true) {
                                                      Navigator.of(
                                                        context,
                                                      ).pushReplacement(
                                                        MaterialPageRoute(
                                                          builder:
                                                              (_) =>
                                                                  const Shell(),
                                                        ),
                                                      );
                                                    } else {
                                                      await api.logout();
                                                      if (context.mounted) {
                                                        CustomSnackBar.show(
                                                          context: context,
                                                          message:
                                                              profileResult['message'] ??
                                                              'Oturum hatası, tekrar giriş yapın.',
                                                          type:
                                                              NotificationType
                                                                  .error,
                                                        );
                                                      }
                                                    }
                                                  } else {
                                                    CustomSnackBar.show(
                                                      context: context,
                                                      message:
                                                          result['message'] ??
                                                          'Giriş başarısız',
                                                      type:
                                                          NotificationType
                                                              .error,
                                                    );
                                                  }
                                                }
                                                : () => setState(
                                                  () => attempted = true,
                                                ),
                                        child: Center(
                                          child: Text(
                                            mode == LoginMode.alias
                                                ? 'Takma Ad ile Giriş'
                                                : 'Telefon ile Giriş',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Premium Kayıt Ol Butonu
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: cs.primary.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 1.5,
                                      ),
                                      color: cs.primary.withValues(alpha: 0.1),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => const RegisterScreen(),
                                            ),
                                          );
                                        },
                                        child: Center(
                                          child: Text(
                                            'Kayıt Ol',
                                            style: TextStyle(
                                              color: cs.primary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryCodeSheet extends StatelessWidget {
  final String selected;
  const _CountryCodeSheet({required this.selected});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('+90 TR'),
            trailing: selected == '+90' ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(context, '+90'),
          ),
          ListTile(
            title: const Text('+1 US'),
            trailing: selected == '+1' ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(context, '+1'),
          ),
          ListTile(
            title: const Text('+44 UK'),
            trailing: selected == '+44' ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(context, '+44'),
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  bool _isSent = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifremi Unuttum'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.lock_reset_rounded, size: 80, color: cs.primary),
            const SizedBox(height: 24),
            Text(
              'Şifrenizi mi unuttunuz?',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Kayıtlı telefon numaranızı girin. Şifrenizi sıfırlamanız için size bir SMS göndereceğiz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            if (!_isSent) ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefon Numarası',
                  hintText: '5xx xxx xx xx',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_phoneController.text.length >= 10) {
                    setState(() => _isSent = true);
                    CustomSnackBar.show(
                      context: context,
                      message: 'Sıfırlama bağlantısı SMS olarak gönderildi.',
                      type: NotificationType.success,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'SMS Gönder',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.5),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'SMS başarıyla gönderildi!\nLütfen telefonunuzu kontrol edin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Giriş Ekranına Dön'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final aliasController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool passwordVisible = false;
  bool attempted = false;
  String countryCode = '+90';

  bool get isValid {
    final passOk = passwordController.text.trim().length >= 6;
    final aliasOk = aliasController.text.trim().length >= 3;
    final digits = phoneController.text.replaceAll(RegExp(r'\D'), '');
    final phoneOk =
        countryCode == '+90' ? digits.length == 10 : digits.length >= 10;
    return aliasOk && phoneOk && passOk;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: Image.asset('logo.png', height: 96)),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: cs.outlineVariant),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                TextField(
                                  controller: aliasController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Takma Ad',
                                    hintText: 'Görünen adınız',
                                    prefixIcon: const Icon(Icons.tag),
                                    errorText:
                                        attempted &&
                                                aliasController.text
                                                        .trim()
                                                        .length <
                                                    3
                                            ? 'Takma ad gerekli'
                                            : null,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Telefon',
                                    hintText:
                                        countryCode == '+90'
                                            ? '5xx xxx xx xx'
                                            : 'Numara',
                                    prefixText: '$countryCode ',
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.expand_more),
                                      onPressed: () async {
                                        final code =
                                            await showModalBottomSheet<String>(
                                              context: context,
                                              builder:
                                                  (_) => _CountryCodeSheet(
                                                    selected: countryCode,
                                                  ),
                                            );
                                        if (code != null) {
                                          setState(() => countryCode = code);
                                        }
                                      },
                                    ),
                                    errorText:
                                        attempted &&
                                                !(countryCode == '+90'
                                                    ? phoneController.text
                                                            .replaceAll(
                                                              RegExp(r'\D'),
                                                              '',
                                                            )
                                                            .length ==
                                                        10
                                                    : phoneController.text
                                                            .replaceAll(
                                                              RegExp(r'\D'),
                                                              '',
                                                            )
                                                            .length >=
                                                        10)
                                            ? 'Telefon numarası geçersiz'
                                            : null,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: passwordController,
                                  obscureText: !passwordVisible,
                                  decoration: InputDecoration(
                                    labelText: 'Şifre',
                                    hintText: '••••••••',
                                    prefixIcon: const Icon(Icons.lock),
                                    errorText:
                                        attempted &&
                                                passwordController.text
                                                        .trim()
                                                        .length <
                                                    6
                                            ? 'Yanlış şifre'
                                            : null,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        passwordVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () =>
                                                passwordVisible =
                                                    !passwordVisible,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Premium Kayıt Ol Butonu
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      colors: [cs.primary, cs.secondary],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: cs.primary.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap:
                                          isValid
                                              ? () async {
                                                setState(
                                                  () => attempted = true,
                                                );
                                                final api = ref.read(
                                                  apiServiceProvider,
                                                );

                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder:
                                                      (context) => const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                );

                                                final alias =
                                                    aliasController.text.trim();
                                                final phone =
                                                    countryCode +
                                                    phoneController.text
                                                        .replaceAll(
                                                          RegExp(r'\D'),
                                                          '',
                                                        );
                                                final password =
                                                    passwordController.text;

                                                final result = await api
                                                    .register(
                                                      alias: alias,
                                                      phone: phone,
                                                      password: password,
                                                    );

                                                if (!context.mounted) {
                                                  return;
                                                }

                                                Navigator.pop(
                                                  context,
                                                ); // Loading'i kapat

                                                if (result['success']) {
                                                  ref.invalidate(
                                                    userProfileProvider,
                                                  );
                                                  // Kayıt sonrası Onboarding'e (Profil Tamamlama) yönlendir
                                                  Navigator.of(
                                                    context,
                                                  ).pushReplacement(
                                                    MaterialPageRoute(
                                                      builder:
                                                          (_) =>
                                                              const OnboardingScreen(),
                                                    ),
                                                  );
                                                } else {
                                                  CustomSnackBar.show(
                                                    context: context,
                                                    message:
                                                        result['message'] ??
                                                        'Kayıt başarısız',
                                                    type:
                                                        NotificationType.error,
                                                  );
                                                }
                                              }
                                              : () => setState(
                                                () => attempted = true,
                                              ),
                                      child: const Center(
                                        child: Text(
                                          'Kayıt Ol',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Premium Girişe Dön Butonu
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: cs.primary.withValues(alpha: 0.5),
                                      width: 1.5,
                                    ),
                                    color: cs.primary.withValues(alpha: 0.1),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Center(
                                        child: Text(
                                          'Girişe dön',
                                          style: TextStyle(
                                            color: cs.primary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});
  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1300), () async {
      if (mounted) {
        final api = ApiService(); // ref yerine doğrudan instance
        final profileResult = await api.getProfile();

        if (mounted) {
          if (profileResult['success'] == true) {
            Navigator.of(
              context,
            ).pushReplacement(MaterialPageRoute(builder: (_) => const Shell()));
          } else {
            // Kullanıcı silinmiş veya token geçersiz
            await api.logout();
            if (mounted) {
              CustomSnackBar.show(
                context: context,
                message:
                    profileResult['message'] ??
                    'Oturum süresi doldu, tekrar giriş yapın.',
                type: NotificationType.error,
              );
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.05).animate(
                    CurvedAnimation(
                      parent: controller,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Image.asset('logo.png', height: 120),
                ),
                const SizedBox(height: 16),
                Text(
                  'Giriş yapılıyor…',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: cs.onPrimary),
                ),
                const SizedBox(height: 16),
                CircularProgressIndicator(color: cs.onPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
