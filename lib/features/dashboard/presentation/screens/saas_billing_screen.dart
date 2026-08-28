import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class SaaSBillingScreen extends ConsumerStatefulWidget {
  const SaaSBillingScreen({super.key});

  @override
  ConsumerState<SaaSBillingScreen> createState() => _SaaSBillingScreenState();
}

class _SaaSBillingScreenState extends ConsumerState<SaaSBillingScreen> {
  String _currentPlan = 'Free Tier';

  void _showUpgradeConfirmation(String planName, String price) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.stars_rounded, size: 48, color: AppTheme.secondaryColor),
              const SizedBox(height: 12),
              Text(
                'Switch to $planName',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Price: $price / month',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Upgrading will grant your organization instant access to all premium features, higher employee limits, and priority support.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentPlan = planName;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully upgraded to $planName!'),
                      backgroundColor: AppTheme.secondaryColor,
                    ),
                  );
                },
                child: Text('Confirm & Subscribe ($price)'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final org = authState.organization;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('SaaS Billing & Subscription'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Active Subscription Header
            Card(
              color: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Active Plan',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentPlan,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Workspace: ${org?.name ?? "Company Space"}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Billing Renewal Date:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('September 28, 2026', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('Available Subscription Plans', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            // Plan Cards
            _buildPlanCard(
              title: 'Free Tier',
              price: '\$0',
              period: '/ month',
              description: 'Essential management tools for early-stage startups and small teams.',
              maxStaff: 'Up to 15 Staff Members',
              features: [
                'Basic Employee Directory',
                'Standard Attendance Check-In',
                'Single Admin User',
                'Community Support',
              ],
              isCurrent: _currentPlan == 'Free Tier',
              isPopular: false,
              color: Colors.blueGrey,
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              title: 'Pro Plan',
              price: '\$29',
              period: '/ month',
              description: 'Advanced workspace automation with GPS Geofencing and HR management tools.',
              maxStaff: 'Up to 100 Staff Members',
              features: [
                'Interactive OpenStreetMap Geofencing',
                'Unlimited HR & Staff Accounts',
                'Real-Time Attendance Overview',
                'Department & Role Breakdown',
                'Exportable Payslip Reports',
                'Priority Email & Chat Support',
              ],
              isCurrent: _currentPlan == 'Pro Plan',
              isPopular: true,
              color: AppTheme.secondaryColor,
              onTap: () => _showUpgradeConfirmation('Pro Plan', '\$29'),
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              title: 'Enterprise Plan',
              price: '\$99',
              period: '/ month',
              description: 'Full-featured enterprise suite with custom security audit logs and dedicated support.',
              maxStaff: 'Unlimited Staff Members',
              features: [
                'All Pro Plan Features Included',
                'Custom Office Geofence Multi-Locations',
                'Security Audit Logs & Compliance',
                'Dedicated Account Manager',
                '24/7 Phone & SLA Support',
              ],
              isCurrent: _currentPlan == 'Enterprise Plan',
              isPopular: false,
              color: Colors.deepPurple,
              onTap: () => _showUpgradeConfirmation('Enterprise Plan', '\$99'),
            ),

            const SizedBox(height: 28),

            // Payment & Invoice History Section
            Text('Billing & Invoice History', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInvoiceRow(
                      invoiceNo: 'INV-2026-08',
                      date: 'Aug 01, 2026',
                      amount: '\$29.00',
                      plan: 'Pro Plan Monthly',
                      status: 'Paid',
                    ),
                    const Divider(height: 24),
                    _buildInvoiceRow(
                      invoiceNo: 'INV-2026-07',
                      date: 'Jul 01, 2026',
                      amount: '\$29.00',
                      plan: 'Pro Plan Monthly',
                      status: 'Paid',
                    ),
                    const Divider(height: 24),
                    _buildInvoiceRow(
                      invoiceNo: 'INV-2026-06',
                      date: 'Jun 01, 2026',
                      amount: '\$29.00',
                      plan: 'Pro Plan Monthly',
                      status: 'Paid',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required String description,
    required String maxStaff,
    required List<String> features,
    required bool isCurrent,
    required bool isPopular,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: isPopular ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPopular
            ? BorderSide(color: color, width: 2)
            : (isCurrent ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isPopular ? color : AppTheme.textPrimaryColor,
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'MOST POPULAR',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  period,
                  style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              maxStaff,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isCurrent
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Current Active Plan'),
                    )
                  : ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                      ),
                      child: Text('Upgrade to $title'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceRow({
    required String invoiceNo,
    required String date,
    required String amount,
    required String plan,
    required String status,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoiceNo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$date • $plan',
                      style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
