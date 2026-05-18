import { PageHeader } from '@/components/PageHeader';
import { OfferEditor } from '@/features/offers/OfferEditor';

export default function NewOfferPage() {
  return (
    <div className="field-stack">
      <PageHeader
        title="Create offer"
        description="Define a campaign, choose the target shop, and set the commercial timing in one place."
      />
      <OfferEditor />
    </div>
  );
}
