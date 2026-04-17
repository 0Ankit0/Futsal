'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useCreateGround, useUpdateGround, type FutsalGround } from '@/hooks/use-futsal';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';

interface GroundFormProps {
  mode: 'create' | 'edit';
  ground?: FutsalGround;
}

type GroundType = FutsalGround['ground_type'];

export function GroundForm({ mode, ground }: GroundFormProps) {
  const router = useRouter();
  const createGround = useCreateGround();
  const updateGround = useUpdateGround(ground?.id ?? 0);
  const [error, setError] = useState('');
  const [formData, setFormData] = useState({
    name: '',
    location: '',
    description: '',
    ground_type: 'outdoor' as GroundType,
    price_per_hour: '1200',
    weekend_price_per_hour: '',
    open_time: '06:00',
    close_time: '22:00',
    slot_duration_minutes: '60',
  });

  useEffect(() => {
    if (!ground) return;
    setFormData({
      name: ground.name,
      location: ground.location,
      description: ground.description ?? '',
      ground_type: ground.ground_type,
      price_per_hour: String(ground.price_per_hour),
      weekend_price_per_hour: ground.weekend_price_per_hour ? String(ground.weekend_price_per_hour) : '',
      open_time: ground.open_time.slice(0, 5),
      close_time: ground.close_time.slice(0, 5),
      slot_duration_minutes: String(ground.slot_duration_minutes),
    });
  }, [ground]);

  const isSaving = createGround.isPending || updateGround.isPending;

  const handleChange = (field: keyof typeof formData, value: string) => {
    setFormData((current) => ({ ...current, [field]: value }));
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setError('');

    const payload = {
      name: formData.name.trim(),
      location: formData.location.trim(),
      description: formData.description.trim() || undefined,
      ground_type: formData.ground_type as GroundType,
      price_per_hour: Number(formData.price_per_hour),
      weekend_price_per_hour: formData.weekend_price_per_hour ? Number(formData.weekend_price_per_hour) : undefined,
      open_time: formData.open_time,
      close_time: formData.close_time,
      slot_duration_minutes: Number(formData.slot_duration_minutes),
    };

    try {
      if (mode === 'create') {
        await createGround.mutateAsync(payload);
      } else if (ground) {
        await updateGround.mutateAsync(payload);
      }
      router.push('/owner/grounds');
    } catch (err) {
      const axiosError = err as { response?: { data?: { detail?: string } } };
      setError(axiosError.response?.data?.detail ?? 'Unable to save this ground right now.');
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>{mode === 'create' ? 'Add a new ground' : 'Edit ground details'}</CardTitle>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          {error && <div className="rounded-lg bg-red-50 p-3 text-sm text-red-600">{error}</div>}

          <div className="grid gap-4 md:grid-cols-2">
            <Input
              id="name"
              label="Ground name"
              value={formData.name}
              onChange={(event) => handleChange('name', event.target.value)}
              required
            />
            <Input
              id="location"
              label="Location"
              value={formData.location}
              onChange={(event) => handleChange('location', event.target.value)}
              required
            />
          </div>

          <div>
            <label htmlFor="description" className="mb-1 block text-sm font-medium text-gray-700">
              Description
            </label>
            <textarea
              id="description"
              rows={4}
              value={formData.description}
              onChange={(event) => handleChange('description', event.target.value)}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-green-500 focus:outline-none focus:ring-2 focus:ring-green-500"
              placeholder="Tell players what makes this ground a good pick."
            />
          </div>

          <div className="grid gap-4 md:grid-cols-3">
            <div>
              <label htmlFor="ground_type" className="mb-1 block text-sm font-medium text-gray-700">
                Ground type
              </label>
              <select
                id="ground_type"
                value={formData.ground_type}
                onChange={(event) => handleChange('ground_type', event.target.value as GroundType)}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-green-500 focus:outline-none focus:ring-2 focus:ring-green-500"
              >
                <option value="outdoor">Outdoor</option>
                <option value="indoor">Indoor</option>
                <option value="hybrid">Hybrid</option>
              </select>
            </div>
            <Input
              id="price_per_hour"
              type="number"
              min="1"
              label="Weekday price / hour"
              value={formData.price_per_hour}
              onChange={(event) => handleChange('price_per_hour', event.target.value)}
              required
            />
            <Input
              id="weekend_price_per_hour"
              type="number"
              min="1"
              label="Weekend price / hour"
              value={formData.weekend_price_per_hour}
              onChange={(event) => handleChange('weekend_price_per_hour', event.target.value)}
            />
          </div>

          <div className="grid gap-4 md:grid-cols-3">
            <Input
              id="open_time"
              type="time"
              label="Open time"
              value={formData.open_time}
              onChange={(event) => handleChange('open_time', event.target.value)}
              required
            />
            <Input
              id="close_time"
              type="time"
              label="Close time"
              value={formData.close_time}
              onChange={(event) => handleChange('close_time', event.target.value)}
              required
            />
            <Input
              id="slot_duration_minutes"
              type="number"
              min="30"
              step="30"
              label="Slot duration (mins)"
              value={formData.slot_duration_minutes}
              onChange={(event) => handleChange('slot_duration_minutes', event.target.value)}
              required
            />
          </div>

          <div className="flex gap-3">
            <Button type="submit" className="bg-green-600 hover:bg-green-700" isLoading={isSaving}>
              {mode === 'create' ? 'Create ground' : 'Save changes'}
            </Button>
            <Button type="button" variant="outline" onClick={() => router.push('/owner/grounds')}>
              Cancel
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
