export const PERMISSIONS = {
  analyticsView: 'Analytics.View',
  reportsGenerate: 'Reports.Generate',
  usersView: 'Users.View',
  usersEdit: 'Users.Edit',
  usersSuspend: 'Users.Suspend',
  usersBan: 'Users.Ban',
  usersExport: 'Users.Export',
  keepersView: 'Keepers.View',
  keepersApprove: 'Keepers.Approve',
  keepersReject: 'Keepers.Reject',
  keepersSuspend: 'Keepers.Suspend',
  shopsView: 'Shops.View',
  shopsCreate: 'Shops.Create',
  shopsEdit: 'Shops.Edit',
  shopsDelete: 'Shops.Delete',
  shopsApprove: 'Shops.Approve',
  shopsReject: 'Shops.Reject',
  offersView: 'Offers.View',
  offersCreate: 'Offers.Create',
  offersEdit: 'Offers.Edit',
  offersDelete: 'Offers.Delete',
  offersApprove: 'Offers.Approve',
  categoriesView: 'Categories.View',
  categoriesCreate: 'Categories.Create',
  categoriesEdit: 'Categories.Edit',
  categoriesDelete: 'Categories.Delete',
  tagsView: 'Tags.View',
  tagsCreate: 'Tags.Create',
  tagsEdit: 'Tags.Edit',
  tagsDelete: 'Tags.Delete',
  routesView: 'Routes.View',
  reviewsView: 'Reviews.View',
  reviewsReply: 'Reviews.Reply',
  loyaltyView: 'Loyalty.View',
  loyaltyEdit: 'Loyalty.Edit',
  rulesView: 'Rules.View',
  rulesEdit: 'Rules.Edit',
  journeysView: 'Journeys.View',
  journeysDelete: 'Journeys.Delete',
  moderationView: 'Moderation.View',
  moderationApprove: 'Moderation.Approve',
  moderationReject: 'Moderation.Reject',
  moderationEdit: 'Moderation.Edit',
  moderationEscalate: 'Moderation.Escalate',
  notificationsView: 'Notifications.View',
  notificationsSend: 'Notifications.Send',
  systemView: 'System.View',
  systemEdit: 'System.Edit',
  settingsEdit: 'Settings.Edit',
  adminsManage: 'Admins.Manage',
} as const;

export type PermissionRequirement = string | string[] | null | undefined;

export function pathPermission(pathname: string): PermissionRequirement {
  if (pathname.startsWith('/dashboard')) return PERMISSIONS.systemView;
  if (pathname.startsWith('/users')) return PERMISSIONS.usersView;
  if (pathname.startsWith('/shops')) return PERMISSIONS.shopsView;
  if (pathname.startsWith('/offers')) return PERMISSIONS.offersView;
  if (pathname.startsWith('/reviews')) return [PERMISSIONS.reviewsView, PERMISSIONS.moderationView];
  if (pathname.startsWith('/notifications')) return PERMISSIONS.notificationsView;
  if (pathname.startsWith('/keepers')) return PERMISSIONS.keepersView;
  if (pathname.startsWith('/journeys')) return PERMISSIONS.journeysView;
  if (pathname.startsWith('/categories')) return PERMISSIONS.categoriesView;
  if (pathname.startsWith('/tags')) return PERMISSIONS.tagsView;
  if (pathname.startsWith('/moderation')) return PERMISSIONS.moderationView;
  if (pathname.startsWith('/settings')) {
    return [PERMISSIONS.systemView, PERMISSIONS.settingsEdit, PERMISSIONS.adminsManage];
  }

  return null;
}

const preferredRouteOrder = [
  { permission: PERMISSIONS.systemView, path: '/dashboard' },
  { permission: PERMISSIONS.moderationView, path: '/moderation' },
  { permission: PERMISSIONS.analyticsView, path: '/journeys' },
  { permission: PERMISSIONS.usersView, path: '/users' },
  { permission: null, path: '/profile' },
] as const;

export function preferredLandingRoute(permissions: string[] = []): string {
  for (const item of preferredRouteOrder) {
    if (!item.permission || permissions.includes(item.permission)) {
      return item.path;
    }
  }

  return '/profile';
}
