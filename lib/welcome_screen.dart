import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Welcome / Disclaimer Screen ───────────────────────────────────────────
//
// Shown the very first time the app is opened (see `main.dart`, where a
// SharedPreferences flag under `WelcomeScreen.seenPrefsKey` decides whether
// to show this or go straight to HomeScreen), and also reachable any time
// afterwards from the "About / Privacy" button in HomeScreen's app bar.

/// The MediGuard privacy policy, opened by the "Read our Privacy Policy" link.
const String privacyPolicyUrl =
    'https://harrylingineni-cmd.github.io/medminder/mediguard-privacy-policy.html';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onContinue,
    this.isFirstLaunch = true,
  });

  /// Called when the user taps the button at the bottom.
  /// On first launch this marks the welcome screen as seen and moves on to
  /// HomeScreen; when reopened from the app bar it just closes this screen.
  final VoidCallback onContinue;

  /// True when this is the mandatory first-launch screen (no way to go back
  /// without tapping the button). False when reopened later from the
  /// "About / Privacy" menu, in which case we show a back arrow too.
  final bool isFirstLaunch;

  /// Opens the privacy policy link in the phone's browser.
  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final uri = Uri.parse(privacyPolicyUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open the privacy policy link.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // On first launch there is nothing to go "back" to yet, so block the
      // Android back button — the user must tap the button to continue.
      canPop: !isFirstLaunch,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: isFirstLaunch
            ? null
            : AppBar(
                backgroundColor: const Color(0xFF1A4B8C),
                foregroundColor: Colors.white,
                title: const Text(
                  'About MediGuard',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Friendly welcome ──────────────────────────────────────
                const Icon(
                  Icons.medication,
                  color: Color(0xFF1A4B8C),
                  size: 72,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome to MediGuard',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A4B8C),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'MediGuard helps you remember to take your '
                  'medications on time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, height: 1.4),
                ),
                const SizedBox(height: 32),

                // ── Disclaimer box ────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5), // soft amber, high contrast
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFCC7A00),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade900,
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Please Read',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'MediGuard is a reminder tool, not a medical '
                        'device. It does not provide medical advice and '
                        'does not guarantee that a medication has been '
                        'taken. It is not a substitute for a doctor or '
                        'pharmacist. Always check the medication label '
                        'before taking any medicine. In an emergency, '
                        'contact your local emergency services.',
                        style: TextStyle(fontSize: 19, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Privacy line with tappable link ───────────────────────
                const Text(
                  'Your information is stored only on your device. '
                  'We do not collect or share your data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 19, height: 1.4),
                ),
                const SizedBox(height: 12),
                Center(
                  child: InkWell(
                    onTap: () => _openPrivacyPolicy(context),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Text(
                        'Read our Privacy Policy',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A4B8C),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // ── Continue button ───────────────────────────────────────
                SizedBox(
                  height: 64,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A4B8C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isFirstLaunch ? 'I Understand — Get Started' : 'Close',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
