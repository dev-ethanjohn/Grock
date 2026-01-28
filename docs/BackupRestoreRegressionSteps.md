# Backup/Restore Regression Steps

## Scenario

Restore a vault backup after an in-app reset and onboarding.

## Preconditions

- At least one cart exists with multiple vault-backed items.
- Items are present in categories (not only shopping-only items).

## Steps

1. Open the Home screen menu.
2. Tap “Save Vault Items Backup”.
3. Perform the in-app “Reset” flow.
4. Complete onboarding.
5. Tap “Restore Vault Items Backup”.
6. Open the Vault and confirm restored items exist.

## Expected

- Vault items and stores are restored from the backup.
- Carts are not restored.

## Notes

- If you want carts restored for debugging, call `restore(includeCarts: true)` in code.
