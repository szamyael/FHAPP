import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../models/order.dart';

class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final steps = _buildSteps();
    return Column(
      children: [
        for (final step in steps)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  step.icon,
                  size: 18,
                  color: step.isError
                      ? scheme.error
                      : switch (step.state) {
                          _StepState.done => FoodHubConstants.brandAccent,
                          _StepState.todo =>
                            step.isCurrent ? scheme.primary : scheme.outline,
                        },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.label,
                    style: step.isCurrent
                        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )
                        : Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<_TimelineStep> _buildSteps() {
    if (status == OrderStatus.declinedBySeller) {
      return const [
        _TimelineStep.done('Order placed'),
        _TimelineStep.current(
          'Declined by seller',
          icon: Icons.cancel_rounded,
          isError: true,
        ),
        _TimelineStep.todo('Preparing'),
        _TimelineStep.todo('Ready for pickup'),
        _TimelineStep.todo('Picked up by rider'),
        _TimelineStep.todo('Rider is on the way'),
        _TimelineStep.todo('Delivered'),
      ];
    }

    final isPending = status == OrderStatus.pendingSellerConfirmation;
    final isPreparing = status == OrderStatus.preparing;
    final isReady = status == OrderStatus.confirmedAwaitingPickup;
    final isPickedUp = status == OrderStatus.pickedUp;
    final isOnTheWay = status == OrderStatus.onTheWay;
    final isDelivered = status == OrderStatus.delivered;

    final preparingDone = isReady || isPickedUp || isOnTheWay || isDelivered;
    final readyDone = isPickedUp || isOnTheWay || isDelivered;
    final pickedUpDone = isOnTheWay || isDelivered;
    final onTheWayDone = isDelivered;

    return [
      const _TimelineStep.done('Order placed'),
      if (isPending)
        const _TimelineStep.current('Pending seller confirmation')
      else
        const _TimelineStep.done('Seller confirmed'),
      if (isPreparing)
        const _TimelineStep.current('Preparing')
      else
        _TimelineStep(
          label: 'Preparing',
          state: preparingDone ? _StepState.done : _StepState.todo,
          isCurrent: false,
        ),
      if (isReady)
        const _TimelineStep.current('Ready for pickup')
      else
        _TimelineStep(
          label: 'Ready for pickup',
          state: readyDone ? _StepState.done : _StepState.todo,
          isCurrent: false,
        ),
      _TimelineStep(
        label: 'Picked up by rider',
        state: (isPickedUp || pickedUpDone) ? _StepState.done : _StepState.todo,
        isCurrent: isPickedUp,
      ),
      _TimelineStep(
        label: 'Rider is on the way',
        state: (isOnTheWay || onTheWayDone) ? _StepState.done : _StepState.todo,
        isCurrent: isOnTheWay,
      ),
      _TimelineStep(
        label: 'Delivered',
        state: isDelivered ? _StepState.done : _StepState.todo,
        isCurrent: isDelivered,
      ),
    ];
  }
}

enum _StepState { todo, done }

class _TimelineStep {
  const _TimelineStep({
    required this.label,
    required this.state,
    required this.isCurrent,
  }) : isError = false,
       iconOverride = null;

  const _TimelineStep.done(this.label)
    : state = _StepState.done,
      isCurrent = false,
      isError = false,
      iconOverride = null;

  const _TimelineStep.todo(this.label)
    : state = _StepState.todo,
      isCurrent = false,
      isError = false,
      iconOverride = null;

  const _TimelineStep.current(
    this.label, {
    IconData? icon,
    this.isError = false,
  }) : state = _StepState.todo,
       isCurrent = true,
       iconOverride = icon;

  final String label;
  final _StepState state;
  final bool isCurrent;
  final bool isError;
  final IconData? iconOverride;

  IconData get icon {
    if (iconOverride != null) return iconOverride!;
    return switch (state) {
      _StepState.done => Icons.check_circle_rounded,
      _StepState.todo =>
        isCurrent
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
    };
  }
}
