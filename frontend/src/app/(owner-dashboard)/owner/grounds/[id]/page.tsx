import { useParams } from 'react-router-dom';
import { useGround } from '@/hooks/use-futsal';
import { GroundForm } from '@/components/owner/ground-form';
import { Skeleton } from '@/components/ui/skeleton';

export default function OwnerGroundEditPage() {
  const params = useParams<{ id: string }>();
  const groundId = Number(params.id);
  const { data: ground, isLoading } = useGround(groundId);

  if (isLoading) {
    return <Skeleton className="h-96 w-full" />;
  }

  if (!ground) {
    return <p className="text-sm text-gray-500">Ground not found.</p>;
  }

  return <GroundForm mode="edit" ground={ground} />;
}
