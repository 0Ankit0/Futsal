'use client';

import { useGround } from '@/hooks/use-futsal';
import { GroundForm } from '@/components/grounds/ground-form';

export default function EditGroundPage({ params }: { params: { id: string } }) {
  const groundId = Number(params.id);
  const { data: ground, isLoading, isError } = useGround(groundId);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Edit Ground</h1>
        <p className="text-sm text-gray-500">Update pricing, hours, or the listing details shown to players.</p>
      </div>
      {isLoading ? (
        <p className="text-sm text-gray-500">Loading ground details...</p>
      ) : isError || !ground ? (
        <p className="text-sm text-red-500">Unable to load this ground.</p>
      ) : (
        <GroundForm mode="edit" ground={ground} />
      )}
    </div>
  );
}
