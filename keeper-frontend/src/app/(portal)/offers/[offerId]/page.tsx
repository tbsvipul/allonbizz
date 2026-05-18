import { PageHeader } from '@/components/PageHeader';
import { OfferEditor } from '@/features/offers/OfferEditor';

export default async function OfferDetailPage({
  params,
}: {
  params: Promise<{ offerId: string }>;
}) {
  const { offerId } = await params;

  return (
    <div className="field-stack">
      <PageHeader
        title="Offer details"
        description="Adjust scheduling, discounts, and assignment for this offer."
      />
      <OfferEditor offerId={offerId} />
    </div>
  );
}
