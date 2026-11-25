import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:koma/features/auth/bloc/auth_cubit.dart';
import 'package:koma/features/auth/bloc/auth_state.dart';
import 'package:koma/l10n/l10n.dart';
import 'package:koma_ui/koma_ui.dart';

/// {@template login_page}
/// Root page for authentication, providing an [AuthCubit] to [LoginView].
/// {@endtemplate}
class LoginPage extends StatelessWidget {
  /// {@macro login_page}
  const new({this.showDevQuickLogin, super.key});

  /// Explicit flag to show or hide the QA quick login button.
  ///
  /// Defaults to `kDebugMode` or `USE_FIREBASE_EMULATOR`.
  final bool? showDevQuickLogin;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AuthCubit(authRepository: context.read<AuthRepository>()),
      child: LoginView(showDevQuickLogin: showDevQuickLogin),
    );
  }
}

/// {@template login_view}
/// Presentation view for user login, registration, and QA quick sign-in.
/// {@endtemplate}
class LoginView extends StatefulWidget {
  /// {@macro login_view}
  const new({this.showDevQuickLogin, super.key});

  /// Explicit flag to show or hide the QA quick login button.
  final bool? showDevQuickLogin;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _submit(AuthState state) {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    unawaited(
      context.read<AuthCubit>().submitCredentials(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: state.isSignUp ? _displayNameController.text : null,
      ),
    );
  }

  String _getAuthErrorMessage(BuildContext context, AuthErrorCode code) {
    final l10n = context.l10n;
    return switch (code) {
      AuthErrorCode.invalidCredentials => l10n.authInvalidCredentialsError,
      AuthErrorCode.emailAlreadyInUse => l10n.authEmailAlreadyInUseError,
      AuthErrorCode.weakPassword => l10n.authWeakPasswordError,
      AuthErrorCode.network => l10n.authNetworkError,
      AuthErrorCode.googleCancelled => l10n.authGoogleCancelledError,
      AuthErrorCode.unknown => l10n.authUnknownError,
    };
  }

  Widget _buildErrorBanner(BuildContext context, AuthErrorCode code) {
    final message = _getAuthErrorMessage(context, code);

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        key: const Key('auth_error_banner'),
        margin: EdgeInsetsDirectional.only(bottom: context.komaSpacing.md),
        padding: EdgeInsetsDirectional.all(context.komaSpacing.md),
        decoration: BoxDecoration(
          color: context.colorScheme.errorContainer,
          borderRadius: BorderRadiusDirectional.circular(context.komaSpacing.xs)
              .resolve(Directionality.of(context)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: context.colorScheme.onErrorContainer,
            ),
            SizedBox(width: context.komaSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.komaSpacing;
    final showDev =
        widget.showDevQuickLogin ??
        (kDebugMode || const bool.fromEnvironment('USE_FIREBASE_EMULATOR'));

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsetsDirectional.all(spacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state.isFailure && state.errorCode != null) {
                    final message = _getAuthErrorMessage(
                      context,
                      state.errorCode!,
                    );
                    unawaited(
                      // Announce provides immediate screen-reader feedback.
                      // ignore: deprecated_member_use
                      SemanticsService.announce(
                        message,
                        Directionality.of(context),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  return Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: ExcludeSemantics(
                              child: ClipRRect(
                                borderRadius: BorderRadiusDirectional.circular(
                                  16,
                                ).resolve(Directionality.of(context)),
                                child: Image.asset(
                                  'assets/branding/koma_app_icon.png',
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.contain,
                                  errorBuilder: (ctx, err, stack) => Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color:
                                          context.colorScheme.primaryContainer,
                                      borderRadius:
                                          BorderRadiusDirectional.circular(
                                            16,
                                          ).resolve(Directionality.of(context)),
                                    ),
                                    child: Icon(
                                      Icons.menu_book_rounded,
                                      size: 40,
                                      color: context
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: spacing.md),
                          Semantics(
                            header: true,
                            child: Text(
                              l10n.appTitle,
                              style: context.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: spacing.xxs),
                          Text(
                            l10n.appTagline,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: spacing.lg),
                          Semantics(
                            header: true,
                            child: Text(
                              state.isSignUp
                                  ? l10n.signUpTitle
                                  : l10n.loginTitle,
                              style: context.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: context.colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: spacing.lg),
                          if (state.isFailure && state.errorCode != null)
                            _buildErrorBanner(context, state.errorCode!),
                          TextFormField(
                            key: const Key('auth_email_input'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.emailLabel,
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.authEmailRequiredError;
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: spacing.md),
                          TextFormField(
                            key: const Key('auth_password_input'),
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: [
                              if (state.isSignUp)
                                AutofillHints.newPassword
                              else
                                AutofillHints.password,
                            ],
                            textInputAction: state.isSignUp
                                ? TextInputAction.next
                                : TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(state),
                            decoration: InputDecoration(
                              labelText: l10n.passwordLabel,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? l10n.showPasswordTooltip
                                    : l10n.hidePasswordTooltip,
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.authPasswordRequiredError;
                              }
                              return null;
                            },
                          ),
                          if (state.isSignUp) ...[
                            SizedBox(height: spacing.md),
                            TextFormField(
                              key: const Key('auth_display_name_input'),
                              controller: _displayNameController,
                              autofillHints: const [AutofillHints.name],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(state),
                              decoration: InputDecoration(
                                labelText: l10n.displayNameLabel,
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                            ),
                          ],
                          SizedBox(height: spacing.lg),
                          FilledButton(
                            key: const Key('auth_submit_button'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            onPressed: state.isSubmitting
                                ? null
                                : () => _submit(state),
                            child: state.isSubmitting
                                ? Semantics(
                                    label: l10n.loadingLabel,
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator.adaptive(
                                        strokeWidth: 2,
                                        semanticsLabel: l10n.loadingLabel,
                                      ),
                                    ),
                                  )
                                : Text(
                                    state.isSignUp
                                        ? l10n.signUpButton
                                        : l10n.signInButton,
                                  ),
                          ),
                          SizedBox(height: spacing.sm),
                          TextButton(
                            key: const Key('auth_toggle_mode_button'),
                            style: TextButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            onPressed: state.isSubmitting
                                ? null
                                : () => context.read<AuthCubit>().toggleMode(),
                            child: Text(
                              state.isSignUp
                                  ? l10n.switchToSignIn
                                  : l10n.switchToSignUp,
                            ),
                          ),
                          SizedBox(height: spacing.md),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsetsDirectional.symmetric(
                                  horizontal: spacing.md,
                                ),
                                child: Text(
                                  'OR',
                                  style: context.textTheme.labelMedium
                                      ?.copyWith(
                                        color: context
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          SizedBox(height: spacing.md),
                          OutlinedButton.icon(
                            key: const Key('auth_google_button'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            icon: const Icon(
                              Icons.g_mobiledata_rounded,
                              size: 28,
                            ),
                            label: Text(l10n.continueWithGoogle),
                            onPressed: state.isSubmitting
                                ? null
                                : () {
                                    unawaited(
                                      context
                                          .read<AuthCubit>()
                                          .signInWithGoogle(),
                                    );
                                  },
                          ),
                          if (showDev) ...[
                            SizedBox(height: spacing.md),
                            FilledButton.tonalIcon(
                              key: const Key('auth_qa_quick_login_button'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              icon: const Icon(Icons.developer_mode_rounded),
                              label: Text(l10n.devQuickLoginButton),
                              onPressed: state.isSubmitting
                                  ? null
                                  : () {
                                      unawaited(
                                        context
                                            .read<AuthCubit>()
                                            .signInWithTestAccount(),
                                      );
                                    },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
