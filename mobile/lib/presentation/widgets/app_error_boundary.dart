import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';

class AppErrorHandler {
  static void init() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('Uncaught Flutter error: ${details.exceptionAsString()}');
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return _GlobalErrorWidget(details: details);
    };
  }
}

class _GlobalErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;
  const _GlobalErrorWidget({required this.details});

  @override
  Widget build(BuildContext context) {
    final t = localeProvider.t;
    return Material(
      color: AppColors.sf(context),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.dng(context),
              ),
              const SizedBox(height: 12),
              Text(
                t('something_went_wrong'),
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (kDebugMode)
                Text(
                  details.exceptionAsString(),
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppErrorBoundary extends StatefulWidget {
  final Widget child;
  const AppErrorBoundary({super.key, required this.child});

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  Object? _error;
  // ignore: unused_field
  StackTrace? _stackTrace;
  int _key = 0;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorRecoveryView(
        onRetry: () {
          setState(() {
            _error = null;
            _stackTrace = null;
            _key++;
          });
        },
      );
    }
    return _ErrorCatcher(
      key: ValueKey(_key),
      onCaught: (error, stack) {
        if (mounted) {
          setState(() {
            _error = error;
            _stackTrace = stack;
          });
        }
      },
      child: widget.child,
    );
  }
}

class _ErrorCatcher extends StatelessWidget {
  final Widget child;
  final void Function(Object, StackTrace) onCaught;
  const _ErrorCatcher({required this.child, required this.onCaught, super.key});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _ErrorRecoveryView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorRecoveryView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = localeProvider.t;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: AppColors.dng(context)),
            const SizedBox(height: 16),
            Text(
              t('something_went_wrong'),
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              t('error_boundary_desc'),
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(t('retry')),
            ),
          ],
        ),
      ),
    );
  }
}
