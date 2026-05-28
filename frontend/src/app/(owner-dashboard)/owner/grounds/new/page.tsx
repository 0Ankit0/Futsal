import { GroundForm } from '@/components/owner/ground-form';

export default function OwnerGroundCreatePage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Add Ground</h1>
        <p className="text-gray-500 text-sm">Create a new ground listing for players to book.</p>
      </div>
      <GroundForm mode="create" />
    </div>
  );
}
