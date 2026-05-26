import { PageHeader } from '@/components/PageHeader';
import { ShopEditor } from '@/features/shops/ShopEditor';

export default async function ShopDetailPage({
  params,
}: {
  params: Promise<{ shopId: string }>;
}) {
  const { shopId } = await params;

  return (
    <div className="field-stack">
      <ShopEditor shopId={shopId} />
    </div>
  );
}
