import 'package:flutter/cupertino.dart';

/// 与 React `LoginModal` 内嵌条款/隐私页对应的独立滚动页（节选核心段落）。
enum MPLegalDocumentKind {
  terms,
  privacy,
}

class MPLegalDocumentPage extends StatelessWidget {
  const MPLegalDocumentPage({
    super.key,
    required this.kind,
  });

  final MPLegalDocumentKind kind;

  @override
  Widget build(BuildContext context) {
    final title = kind == MPLegalDocumentKind.terms
        ? 'MemoPin Terms of Service'
        : 'MemoPin Privacy Policy';
    const subtitle = 'Last updated: Jan 19 2026';
    final paragraphs = kind == MPLegalDocumentKind.terms ? _kTermsParagraphs : _kPrivacyParagraphs;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              subtitle,
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            ...paragraphs.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  p,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Contact: support@memopin.ai · https://www.memopin.ai',
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> _kTermsParagraphs = <String>[
  'Welcome to MemoPin. These Terms of Service ("Terms") govern your use of the MemoPin mobile application, devices, and related services (collectively, the "Service"), provided by MeetSummer Technology Limited ("we", "our", or "us").',
  'By accessing or using MemoPin, you agree to these Terms. If you do not agree, please do not use the Service.',
  'MemoPin is an AI-powered memory companion that helps users capture, organize, and recall conversations and thoughts. The Service may include audio recording, transcription, summarization, AI-generated insights, and cloud-based synchronization features.',
  'You must be at least 13 years old (or the minimum legal age in your jurisdiction) to use MemoPin. You are responsible for lawful use of recording features and for obtaining consent where required by law.',
  'AI-generated transcripts, summaries, or insights may be incomplete or inaccurate and are for informational purposes only; MemoPin does not provide legal, medical, or professional advice.',
  'To the maximum extent permitted by law, MemoPin shall not be liable for indirect or consequential damages or loss of data. Features may change or be discontinued. These Terms are governed by applicable law in your jurisdiction as specified in the full legal document.',
];

const List<String> _kPrivacyParagraphs = <String>[
  'MemoPin ("we", "our", or "us") respects your privacy. This Privacy Policy explains how the MemoPin mobile application and related services collect, use, and safeguard information.',
  'Audio is collected only when you explicitly choose to record. Recordings may be transcribed and processed by AI to generate transcripts, summaries, action items, and insights associated with your account.',
  'We may collect account identifiers, device and app version information, and basic usage logs. We do not sell your personal data or use it for third-party advertising.',
  'You are responsible for ensuring appropriate consent from participants when recording conversations. We use industry-standard security practices including encryption in transit and at rest where applicable.',
  'You may view, export, or delete your content and request account deletion. Third-party providers (cloud, speech-to-text, AI) are bound by contractual obligations to protect your data.',
  'MemoPin is not intended for children under the minimum age required by law. International users’ data may be processed across regions with appropriate safeguards. We may update this policy and notify you of material changes.',
];
