I have identified a potential cause for the abrupt cancellation of the zoom transition in `HomeCartRowView`.

The issue is likely due to **Gesture Conflict** in `ActiveCarts.swift`. Specifically, the `HomeCartRowView` is wrapped in a `Button`, but it also has an explicit `.onLongPressGesture` attached to it, along with a `.contextMenu`.

**The Conflict:**
1.  **`Button`**: Handles the Tap gesture to trigger the navigation (`viewModel.selectCart(cart)`).
2.  **`.contextMenu`**: Automatically handles Long Press gestures.
3.  **`.onLongPressGesture`**: An additional manual gesture recognizer attached to the same view.

When you tap the view, the presence of multiple gesture recognizers (especially the manual `onLongPressGesture` alongside the `Button`'s tap and `contextMenu`'s long press) can cause the system to be uncertain about the user's intent. This can lead to a state where the tap is initially registered, starting the transition, but then the gesture system cancels it or resets the view state because of the conflicting gesture requirements.

**Plan:**
1.  **Modify `ActiveCarts.swift`**:
    *   Remove the explicit `.onLongPressGesture` modifier from the `HomeCartRowView` inside the `Button`.
    *   The `.contextMenu` provides its own interaction and haptics, so the manual gesture is redundant and harmful in this context.
    *   This will simplify the gesture hierarchy and allow the `Button` to reliably handle the tap for the zoom transition.

**Verification:**
After applying this change, the tap interaction should be cleaner, and the zoom transition to `CartDetailScreen` should be stable without abrupt cancellations.
