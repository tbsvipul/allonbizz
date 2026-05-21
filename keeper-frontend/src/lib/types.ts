export interface UserProfile {
  userId: string;
  email: string;
  phoneNumber: string;
  firstName: string;
  lastName: string;
  profilePhotoUrl?: string | null;
  role: string;
}

export interface KeeperDocument {
  id: string;
  name: string;
  type: string;
  url: string;
  status: string;
  reviewNotes?: string | null;
  reviewedAt?: string | null;
}

export interface KeeperReviewMessage {
  messageId: string;
  messageType: string;
  message: string;
  adminName: string;
  isReadByKeeper: boolean;
  createdAt: string;
}

export interface KeeperProfile {
  keeperId: string;
  userId: string;
  businessName: string;
  email: string;
  contactPhone?: string | null;
  businessLicense?: string | null;
  gstNumber?: string | null;
  panNumber?: string | null;
  socialLinksJson?: string | null;
  status: string;
  rejectionReason?: string | null;
  holdReason?: string | null;
  holdUntil?: string | null;
  approvedAt?: string | null;
  documents: KeeperDocument[];
  reviewMessages: KeeperReviewMessage[];
  identityProofType?: string | null;
  identityProofNumber?: string | null;
  identityProofImage?: string | null;
  businessLicenseNumber?: string | null;
  businessLicenseImage?: string | null;
  gstCertificateImage?: string | null;
  panCardImage?: string | null;
  addressProofType?: string | null;
  addressProofImage?: string | null;
  shopFrontImage?: string | null;
  shopInsideImage?: string | null;
}

export interface ReviewMessagesReadResult {
  updatedCount: number;
}

export interface SessionUser extends UserProfile {
  keeper: KeeperProfile | null;
  canManage: boolean;
}

export interface RedemptionTrendPoint {
  date: string;
  count: number;
}

export interface KeeperDashboard {
  activeOffersCount: number;
  totalRedemptions: number;
  totalSalesValue: number;
  redemptionTrend: RedemptionTrendPoint[];
}

export interface TrafficPoint {
  hour: number;
  predictedCount: number;
}

export interface KeeperTraffic {
  currentViewersNearShop: number;
  predictedTraffic: TrafficPoint[];
}

export interface KeeperShopAnalytics {
  shopId: string;
  shopName: string;
  offerCount: number;
  redemptionCount: number;
  savings: number;
}

export interface KeeperAnalytics {
  totalShops: number;
  activeShops: number;
  totalOffers: number;
  activeOffers: number;
  totalRedemptions: number;
  totalSavings: number;
  redemptionTrend: RedemptionTrendPoint[];
  shops: KeeperShopAnalytics[];
}

export interface ShopSummary {
  id: string;
  name: string;
  businessName: string;
  location: string;
  category: string;
  status: string;
  isVerified: boolean;
  latitude?: number | null;
  longitude?: number | null;
  imageUrl?: string | null;
}

export interface ShopOfferSummary {
  offerId: string;
  title: string;
  status: string;
  endDate: string;
}

export interface ShopDetail {
  shopId: string;
  name: string;
  description?: string | null;
  address?: string | null;
  phoneNumber?: string | null;
  email?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  categoryName?: string | null;
  categoryId?: string | null;
  keeperBusinessName?: string | null;
  keeperId: string;
  isActive: boolean;
  isVerified: boolean;
  isOpen: boolean;
  notificationRadius?: number | null;
  imageUrl?: string | null;
  tags: string[];
  amenities: string[];
  createdAt: string;
  recentOffers: ShopOfferSummary[];
}

export interface OfferDetail {
  offerId: string;
  shopId: string;
  shopName: string;
  title: string;
  description?: string | null;
  discountPercentage?: number | null;
  discountAmount?: number | null;
  startDate: string;
  endDate: string;
  termsAndConditions?: string | null;
  status: string;
  redemptionCount: number;
  createdAt: string;
}

export interface ReviewItem {
  reviewId: string;
  userId: string;
  userFullName: string;
  shopId?: string | null;
  shopName: string;
  offerId?: string | null;
  offerTitle?: string | null;
  rating: number;
  comment?: string | null;
  reply?: string | null;
  repliedAt?: string | null;
  createdAt: string;
  status: string;
}

export interface LoyaltyProgram {
  shopId: string;
  configured: boolean;
  isEnabled: boolean;
  programName?: string | null;
  pointsPerRedemption: number;
  minimumPointsToRedeem: number;
  rewardDescription?: string | null;
  termsAndConditions?: string | null;
  updatedAt?: string | null;
}

export interface CategoryTree {
  categoryId: string;
  name: string;
  icon: string;
  color: string;
  description?: string | null;
  parentCategoryId?: string | null;
  displayOrder: number;
  isActive: boolean;
  businessCount: number;
  createdAt: string;
  updatedAt: string;
  children: CategoryTree[];
}

export interface BulkOfferUploadRowError {
  rowNumber: number;
  message: string;
}

export interface BulkOfferUploadResult {
  importedCount: number;
  failedRowCount: number;
  failedRows: BulkOfferUploadRowError[];
}
