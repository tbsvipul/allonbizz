import { PageHeader } from '@/components/PageHeader';
import { ShopEditor } from '@/features/shops/ShopEditor';

export default function NewShopPage() {
  return (
    <div className="field-stack">
      <PageHeader
        title="Create shop"
        description="Register a new location with address, category, coordinates, and public listing basics."
      />
      <ShopEditor />
    </div>
  );
}
