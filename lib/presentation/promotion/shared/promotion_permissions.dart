/// Matches BE `src/config/permissions.json`'s `promotions` module access:
/// TENANT_OWNER/BRANCH_MANAGER/SUPER_ADMIN have create/update/delete;
/// STAFF has read/calculate/apply only; WAREHOUSE_MANAGER has no access at
/// all. SUPER_ADMIN never reaches this screen (excluded from the CRM menu
/// group in `work_view.dart`), so it's not special-cased here.
bool canManagePromotions(String? role) {
  return role == 'TENANT_OWNER' || role == 'BRANCH_MANAGER';
}
