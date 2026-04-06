import 'package:flutter/material.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// 法律文档类型：服务条款或隐私政策。
enum MPLegalDocumentKind {
  terms,
  privacy,
}

/// 展示 MemoPin 服务条款或隐私政策全文。
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
    final lastUpdated = kind == MPLegalDocumentKind.terms
        ? 'Last updated: Jan 13, 2025'
        : 'Last updated: Jun 10, 2024';
    final sections =
        kind == MPLegalDocumentKind.terms ? _buildTermsSections() : _buildPrivacySections();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: OmiFontSize.t13_22,
                        fontWeight: OmiFontWeight.bold,
                        color: mainTextColor,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _MPLegalCloseButton(onPressed: () => Navigator.of(context).pop<void>()),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                lastUpdated,
                style: TextStyle(
                  color: secondTextColor,
                  fontSize: OmiFontSize.t6_15,
                  fontWeight: OmiFontWeight.regular,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: sections,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 右上角圆形关闭按钮（浅灰底 + X）。
class _MPLegalCloseButton extends StatelessWidget {
  const _MPLegalCloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: lineColor,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            Icons.close,
            size: 18,
            color: mainTextColor,
          ),
        ),
      ),
    );
  }
}

// —— Terms ——

List<Widget> _buildTermsSections() {
  return [
    _MPBodyParagraph(
      'Welcome to MemoPin. These Terms of Service (“Terms”) govern your use of the MemoPin mobile application, devices, and related services (collectively, the “Service”), provided by MeetSummer Technology Limited (“we”, “our”, or “us”).',
    ),
    _MPBodyParagraph(
      'By accessing or using MemoPin, you agree to these Terms. If you do not agree, please do not use the Service.',
    ),
    const SizedBox(height: 16),
    _MPSectionHeading('1. Description of the Service'),
    _MPBodyParagraph(
      'MemoPin is an AI-powered memory companion. The Service may include features such as audio recording, transcription, summarization, AI-generated insights, and cloud-based synchronization across your devices.',
    ),
    const SizedBox(height: 16),
    _MPSectionHeading('2. Eligibility'),
    _MPBodyParagraphRich(
      spans: [
        const TextSpan(text: 'You must be at least '),
        TextSpan(text: '13 years old', style: TextStyle(fontWeight: OmiFontWeight.bold)),
        const TextSpan(
          text: ' (or the minimum legal age in your jurisdiction) to use MemoPin.',
        ),
      ],
    ),
    const SizedBox(height: 16),
    _MPSectionHeading('3. User Responsibilities'),
    _MPSubHeading('3.1 Lawful Use & Recording Consent'),
    _MPBulletList(const [
      'You must comply with applicable laws when using recording features, including laws governing consent, notification, and one-party or two-party recording rules in your region.',
      'You are responsible for obtaining any required consent from participants before recording.',
      'You must not use the Service to record others in violation of law or without permission where required.',
    ]),
    const SizedBox(height: 12),
    _MPSubHeading('3.2 Account Security'),
    _MPBodyParagraph(
      'You are responsible for maintaining the confidentiality of your account credentials and for all activity under your account. Notify us promptly if you suspect unauthorized access.',
    ),
    const SizedBox(height: 16),
    _MPSectionHeading('4. AI-Generated Content Disclaimer'),
    _MPBulletList(const [
      'AI-generated content (including transcripts, summaries, and insights) may be incomplete, inaccurate, or outdated.',
      'Such content is provided for informational purposes only and does not constitute legal, medical, financial, or other professional advice.',
      'You are solely responsible for decisions made based on AI-generated content.',
    ]),
    const SizedBox(height: 16),
    _MPSectionHeading('5. Data & Privacy'),
    _MPBodyParagraph(
      'Our collection and use of personal information is described in our Privacy Policy. You retain ownership of content you create, subject to the license needed to operate the Service.',
    ),
    const SizedBox(height: 16),
    _MPSectionHeading('6. Devices, Availability & Changes'),
    _MPBulletList(const [
      'The Service may evolve over time; we may add, modify, or remove features.',
      'We may perform maintenance that results in temporary downtime or degraded performance.',
      'We do not guarantee that the Service will be uninterrupted or error-free.',
    ]),
    const SizedBox(height: 16),
    _MPSectionHeading('7. Beta & Experimental Features'),
    _MPBulletList(const [
      'Beta or experimental features are provided “as is,” may contain bugs, and may not be fully reliable.',
      'We may change or discontinue these features at any time without liability.',
    ]),
    const SizedBox(height: 16),
    _MPSectionHeading('8. Limitation of Liability'),
    _MPBulletList(const [
      'To the maximum extent permitted by law, we are not liable for any indirect, incidental, special, consequential, or punitive damages.',
      'We are not liable for loss of data, profits, or business opportunities arising from your use of the Service.',
      'Our total liability for any claim related to the Service is limited to the greater of amounts you paid us for the Service in the twelve (12) months before the claim or one hundred U.S. dollars (USD \$100), except where prohibited by law.',
    ]),
    const SizedBox(height: 16),
    _MPSectionHeading('9. Termination'),
    _MPBodyParagraph(
      'We may suspend or terminate your access to the Service if you violate these Terms or if we are required to do so by law or to protect the Service or other users.',
    ),
    _MPBodyParagraph(
      'You may stop using the Service at any time. Upon account deletion, your data will be handled as described in our Privacy Policy.',
    ),
    const SizedBox(height: 16),
    _MPSectionHeading('10. Governing Law'),
    _MPBodyParagraph(
      'These Terms are governed by the laws of [Jurisdiction to be specified], without regard to conflict-of-law principles.',
    ),
    const SizedBox(height: 16),
    _MPContactCard(
      introLine: 'If you have questions about these Terms, please contact us:',
      companyName: 'MeetSummer Technology Limited',
      onEmailTap: () => _mpLaunchUrl('mailto:support@memopin.ai'),
      onWebsiteTap: () => _mpLaunchUrl('https://www.memopin.ai'),
    ),
  ];
}

// —— Privacy ——

List<Widget> _buildPrivacySections() {
  return [
    _MPBodyParagraph(
      'MemoPin (“we”, “our”, or “us”) respects your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard information when you use the MemoPin mobile application and related services.',
    ),
    const SizedBox(height: 16),
    _MPSectionHeading('1. What MemoPin Is'),
    _MPBodyParagraph(
      'MemoPin is an AI-powered memory companion designed to help you capture conversations and recall what matters—through recording, transcription, summarization, and intelligent recall features.',
    ),
    const SizedBox(height: 16),
    _MPSectionHeading('2. Information We Collect'),
    _MPSubHeading('2.1 Audio Data (User-Initiated)'),
    _MPBulletList(const [
      'We collect audio only when you explicitly start a recording within the app.',
      'We do not continuously listen to or record audio in the background without your clear action to record.',
    ]),
    const SizedBox(height: 12),
    _MPSubHeading('2.2 Transcripts & AI-Generated Content'),
    _MPBodyParagraph(
      'We process your recordings to generate transcripts, summaries, action items, insights, and related metadata that you can view and manage in the app.',
    ),
    const SizedBox(height: 12),
    _MPSubHeading('2.3 Account & Basic Usage Information'),
    _MPBulletList(const [
      'We may collect your email address and account identifiers needed to create and secure your account.',
      'We may collect device and app information (such as device model, OS version, and app version) and basic usage logs to operate and improve the Service.',
      'We do not collect your contacts or photos for advertising purposes.',
    ]),
    const SizedBox(height: 16),
    _MPSectionHeading('3. How We Use Your Information'),
    _MPBulletList(const [
      'To provide core features, including transcription, summarization, syncing, and AI-assisted recall.',
      'To maintain security, prevent abuse, and troubleshoot issues.',
      'To improve reliability and develop new features.',
      'To communicate with you about the Service (such as support responses or important notices).',
    ]),
    const SizedBox(height: 12),
    _MPBodyParagraphRich(
      spans: [
        TextSpan(text: 'We do not sell your personal data.', style: TextStyle(fontWeight: OmiFontWeight.bold)),
      ],
    ),
    const SizedBox(height: 8),
    _MPBodyParagraphRich(
      spans: [
        TextSpan(text: 'We do not use your data for advertising.', style: TextStyle(fontWeight: OmiFontWeight.bold)),
      ],
    ),
    const SizedBox(height: 16),
    _MPSectionHeading('4. Audio Recording & Consent'),
    _MPBulletList(const [
      'You are responsible for complying with applicable laws and for obtaining consent from participants when recording conversations, where required.',
      'The app provides visible recording controls; you should only record when you are permitted to do so under applicable law.',
    ]),
    const SizedBox(height: 16),
    _MPSectionHeading('5. Data Storage & Security'),
    _MPBulletList(const [
      'We use secure cloud infrastructure to store and process your data.',
      'We implement industry-standard safeguards, including encryption in transit and at rest where applicable.',
      'Access to personal data is limited to authorized personnel and service providers who need it to operate the Service.',
    ]),
    const SizedBox(height: 16),
    _MPSectionHeading('6. Data Ownership & Control'),
    _MPBodyParagraph('You own your data.'),
    const SizedBox(height: 8),
    _MPBodyParagraph('You can:'),
    _MPBulletList(const [
      'View, export, or delete certain content through features we provide in the app, where available.',
      'Request account deletion, which will initiate removal of your account data in line with our retention practices and legal obligations.',
    ]),
    _MPBodyParagraph(
      'After account deletion, residual copies may persist for a limited period in backups before being overwritten.',
    ),
    const SizedBox(height: 16),
    _MPSectionHeading('7. Third-Party Services'),
    _MPBulletList(const [
      'Cloud infrastructure providers that host and process data.',
      'Speech-to-text and related audio processing services.',
      'AI analysis providers that help generate summaries and insights.',
    ]),
    _MPBodyParagraph(
      'These providers are contractually required to protect your information and use it only to provide services to us.',
    ),
    const SizedBox(height: 16),
    _MPSectionHeading('8. Children’s Privacy'),
    _MPBodyParagraph(
      'MemoPin is not directed to children under 13, and we do not knowingly collect personal information from children under 13.',
    ),
    _MPBodyParagraph(
      'If you believe we have collected information from a child under 13, please contact us and we will take appropriate steps.',
    ),
    const SizedBox(height: 16),
    _MPSectionHeading('9. International Users'),
    _MPBodyParagraph(
      'If you access the Service from outside your home country, your information may be processed in countries where we or our providers operate.',
    ),
    _MPBodyParagraph(
      'Where required, we implement appropriate safeguards for international transfers in accordance with applicable law.',
    ),
    const SizedBox(height: 16),
    _MPSectionHeading('10. Changes to This Policy'),
    _MPBodyParagraph(
      'We may update this Privacy Policy from time to time. We will post the updated policy in the app and update the “Last updated” date.',
    ),
    _MPBodyParagraph(
      'If changes are material, we will provide additional notice as appropriate (such as an in-app notice or email, where we have your contact information).',
    ),
    const SizedBox(height: 16),
    _MPContactCard(
      introLine: 'If you have questions about this Privacy Policy, please contact us:',
      companyName: 'MeetSmarter Technology Limited',
      onEmailTap: () => _mpLaunchUrl('mailto:support@memopin.ai'),
      onWebsiteTap: () => _mpLaunchUrl('https://www.memopin.ai'),
    ),
  ];
}

// —— Shared widgets ——

class _MPSectionHeading extends StatelessWidget {
  const _MPSectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: OmiFontSize.t7_16,
          fontWeight: OmiFontWeight.bold,
          color: mainTextColor,
          height: 1.35,
        ),
      ),
    );
  }
}

class _MPSubHeading extends StatelessWidget {
  const _MPSubHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: OmiFontSize.t6_15,
          fontWeight: OmiFontWeight.bold,
          color: mainTextColor,
          height: 1.35,
        ),
      ),
    );
  }
}

class _MPBodyParagraph extends StatelessWidget {
  const _MPBodyParagraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: OmiFontSize.t6_15,
          height: 1.35,
          color: mainTextColor,
          fontWeight: OmiFontWeight.regular,
        ),
      ),
    );
  }
}

class _MPBodyParagraphRich extends StatelessWidget {
  const _MPBodyParagraphRich({required this.spans});

  final List<InlineSpan> spans;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text.rich(
        TextSpan(
          style: TextStyle(
            fontSize: OmiFontSize.t6_15,
            height: 1.35,
            color: mainTextColor,
            fontWeight: OmiFontWeight.regular,
          ),
          children: spans,
        ),
      ),
    );
  }
}

class _MPBulletList extends StatelessWidget {
  const _MPBulletList(this.items);

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((line) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '•',
                  style: TextStyle(
                    fontSize: OmiFontSize.t6_15,
                    color: mainTextColor,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  line,
                  style: TextStyle(
                    fontSize: OmiFontSize.t6_15,
                    height: 1.35,
                    color: mainTextColor,
                    fontWeight: OmiFontWeight.regular,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// 底部联系信息卡片（浅灰圆角背景）。
class _MPContactCard extends StatelessWidget {
  const _MPContactCard({
    required this.introLine,
    required this.companyName,
    required this.onEmailTap,
    required this.onWebsiteTap,
  });

  final String introLine;
  final String companyName;
  final VoidCallback onEmailTap;
  final VoidCallback onWebsiteTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pageColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '11. Contact Us',
            style: TextStyle(
              fontSize: OmiFontSize.t7_16,
              fontWeight: OmiFontWeight.bold,
              color: mainTextColor,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            introLine,
            style: TextStyle(
              fontSize: OmiFontSize.t6_15,
              height: 1.35,
              color: mainTextColor,
              fontWeight: OmiFontWeight.regular,
            ),
          ),
          const SizedBox(height: 12),
          _MPContactRow(label: 'Company', value: companyName),
          const SizedBox(height: 8),
          const _MPContactRow(label: 'Product', value: 'MemoPin'),
          const SizedBox(height: 8),
          _MPContactLinkRow(
            label: 'Email',
            linkText: 'support@memopin.ai',
            onTap: onEmailTap,
          ),
          const SizedBox(height: 8),
          _MPContactLinkRow(
            label: 'Website',
            linkText: 'https://www.memopin.ai',
            onTap: onWebsiteTap,
          ),
        ],
      ),
    );
  }
}

class _MPContactRow extends StatelessWidget {
  const _MPContactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: OmiFontSize.t6_15,
          height: 1.4,
          color: mainTextColor,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(fontWeight: OmiFontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _MPContactLinkRow extends StatelessWidget {
  const _MPContactLinkRow({
    required this.label,
    required this.linkText,
    required this.onTap,
  });

  final String label;
  final String linkText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: OmiFontSize.t6_15,
            height: 1.4,
            color: mainTextColor,
            fontWeight: OmiFontWeight.bold,
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Text(
              linkText,
              style: TextStyle(
                fontSize: OmiFontSize.t6_15,
                height: 1.4,
                color: blueTextColor,
                fontWeight: OmiFontWeight.regular,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 在系统浏览器或邮件客户端中打开链接。
Future<void> _mpLaunchUrl(String urlString) async {
  final uri = Uri.parse(urlString);
  if (!await canLaunchUrl(uri)) {
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
