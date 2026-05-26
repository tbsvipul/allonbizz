import { PageHeader } from '@/components/PageHeader';
import { ShopEditor } from '@/features/shops/ShopEditor';

export default function NewShopPage() {
  return (
    <div className="field-stack">
      <ShopEditor />
    </div>
  );
}
