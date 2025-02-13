import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class OrderForm extends StatefulWidget {
  final bool isEditing;
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic> data) onSubmit;
  final VoidCallback onCancel;

  const OrderForm({
    super.key,
    this.isEditing = false,
    this.initialData,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  late final TextEditingController _orderIdController;
  late final TextEditingController _customerNameController;
  late final TextEditingController _trackingIdController;
  late final TextEditingController _designUrlController;
  
  String _orderStatus = 'Prepaid';
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    _orderIdController = TextEditingController(text: widget.initialData?['orderId'] ?? '');
    _customerNameController = TextEditingController(text: widget.initialData?['customerName'] ?? '');
    _trackingIdController = TextEditingController(text: widget.initialData?['trackingId'] ?? '');
    _designUrlController = TextEditingController(text: widget.initialData?['designUrl'] ?? '');
    _orderStatus = widget.initialData?['orderstatus'] ?? 'Prepaid';
    _status = widget.initialData?['status'] ?? 'pending';
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _customerNameController.dispose();
    _trackingIdController.dispose();
    _designUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      try {
        final formData = {
          'orderId': _orderIdController.text,
          'customerName': _customerNameController.text,
          'trackingId': _trackingIdController.text,
          'designUrl': _designUrlController.text,
          'orderstatus': _orderStatus,
          'status': _status,
          'products': widget.initialData?['products'] ?? [],
        };
        await widget.onSubmit(formData);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Basic Order Details Section
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Basic Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _orderIdController,
                          decoration: const InputDecoration(
                            labelText: 'Order ID',
                            prefixIcon: Icon(Iconsax.document),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Order ID is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _customerNameController,
                          decoration: const InputDecoration(
                            labelText: 'Customer Name',
                            prefixIcon: Icon(Iconsax.user),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Customer name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Status Section
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _orderStatus,
                          decoration: const InputDecoration(
                            labelText: 'Payment Status',
                            prefixIcon: Icon(Iconsax.money),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Prepaid', child: Text('Prepaid')),
                            DropdownMenuItem(value: 'COD', child: Text('COD')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _orderStatus = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _status,
                          decoration: const InputDecoration(
                            labelText: 'Order Status',
                            prefixIcon: Icon(Iconsax.status),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'pending', child: Text('Pending')),
                            DropdownMenuItem(value: 'completed', child: Text('Completed')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _status = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Additional Details Section
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _designUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Design URL',
                      prefixIcon: Icon(Iconsax.link),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _trackingIdController,
                    decoration: const InputDecoration(
                      labelText: 'Tracking/AWB Number',
                      prefixIcon: Icon(Iconsax.truck),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(widget.isEditing ? 'Update Order' : 'Create Order'),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 