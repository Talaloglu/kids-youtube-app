import 'dart:math';
import 'package:flutter/material.dart';

class ParentalGate extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSuccess;

  const ParentalGate({super.key, required this.child, this.onSuccess});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _ParentalGateDialog(),
    );
    return result ?? false;
  }

  @override
  State<ParentalGate> createState() => _ParentalGateState();
}

class _ParentalGateState extends State<ParentalGate> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final allowed = await ParentalGate.show(context);
        if (allowed && widget.onSuccess != null) {
          widget.onSuccess!();
        }
      },
      child: widget.child,
    );
  }
}

class _ParentalGateDialog extends StatefulWidget {
  const _ParentalGateDialog();

  @override
  State<_ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<_ParentalGateDialog> {
  late int _num1;
  late int _num2;
  late int _answer;
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateProblem();
  }

  void _generateProblem() {
    final random = Random();
    _num1 = random.nextInt(10) + 1; // 1-10
    _num2 = random.nextInt(10) + 1; // 1-10
    _answer = _num1 * _num2;
  }

  void _checkAnswer() {
    final input = int.tryParse(_controller.text.trim());
    if (input == _answer) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _error = 'Incorrect. Try again.';
        _controller.clear();
        _generateProblem(); // New problem on wrong answer
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Parental Gate'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Please solve this to continue:'),
          const SizedBox(height: 16),
          Text(
            '$_num1 x $_num2 = ?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Answer',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _checkAnswer(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _checkAnswer, child: const Text('Submit')),
      ],
    );
  }
}
