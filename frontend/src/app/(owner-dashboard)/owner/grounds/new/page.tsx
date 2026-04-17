'use client';

import { GroundForm } from '@/components/grounds/ground-form';

export default function NewGroundPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Add Ground</h1>
        <p className="text-sm text-gray-500">Create a new ground so players can start booking slots.</p>
      </div>
      <GroundForm mode="create" />
    </div>
  );
}
