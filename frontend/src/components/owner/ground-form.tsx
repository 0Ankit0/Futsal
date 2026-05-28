import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useCreateGround, useUpdateGround, type FutsalGround } from '@/hooks/use-futsal';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

export type GroundFormValues = {
  name: string;
  location: string;
  description: string;
  ground_type: 'indoor' | 'outdoor' | 'hybrid';
  price_per_hour: string;
  weekend_price_per_hour: string;
  open_time: string;
  close_time: string;
  slot_duration_minutes: string;
  peak_hours_start: string;
  peak_hours_end: string;
  peak_price_multiplier: string;
  amenities: string;
};

const EMPTY_VALUES: GroundFormValues = {
  name: '',
  location: '',
  description: '',
  ground_type: 'outdoor',
  price_per_hour: '',
  weekend_price_per_hour: '',
  open_time: '06:00',
  close_time: '22:00',
  slot_duration_minutes: '60',
  peak_hours_start: '',
  peak_hours_end: '',
  peak_price_multiplier: '1',
  amenities: '{"parking": true, "shower": false, "wifi": false}',
};

function toValues(ground?: FutsalGround | null): GroundFormValues {
  if (!ground) return EMPTY_VALUES;
  return {
    name: ground.name ?? '',
    location: ground.location ?? '',
    description: ground.description ?? '',
    ground_type: ground.ground_type ?? 'outdoor',
    price_per_hour: String(ground.price_per_hour ?? ''),
    weekend_price_per_hour: ground.weekend_price_per_hour ? String(ground.weekend_price_per_hour) : '',
    open_time: ground.open_time?.slice(0, 5) ?? '06:00',
    close_time: ground.close_time?.slice(0, 5) ?? '22:00',
    slot_duration_minutes: String(ground.slot_duration_minutes ?? 60),
    peak_hours_start: ground.peak_hours_start?.slice(0, 5) ?? '',
    peak_hours_end: ground.peak_hours_end?.slice(0, 5) ?? '',
    peak_price_multiplier: String(ground.peak_price_multiplier ?? 1),
    amenities: ground.amenities ? JSON.stringify(ground.amenities, null, 2) : '{"parking": true, "shower": false, "wifi": false}',
  };
}

function parseAmenities(raw: string) {
  try {
    return raw.trim() ? JSON.parse(raw) : undefined;
  } catch {
    return undefined;
  }
}

export function GroundForm({ mode, ground }: { mode: 'create' | 'edit'; ground?: FutsalGround | null }) {
  const navigate = useNavigate();
  const createGround = useCreateGround();
  const updateGround = useUpdateGround(ground?.id ?? 0);
  const [values, setValues] = useState<GroundFormValues>(() => toValues(ground));
  const [error, setError] = useState('');

  useEffect(() => {
    setValues(toValues(ground));
  }, [ground]);

  const isSubmitting = mode === 'create' ? createGround.isPending : updateGround.isPending;

  const setField = (key: keyof GroundFormValues, value: string) => {
    setValues((current) => ({ ...current, [key]: value }));
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setError('');

    const payload = {
      name: values.name.trim(),
      location: values.location.trim(),
      description: values.description.trim() || undefined,
      ground_type: values.ground_type,
      price_per_hour: Number(values.price_per_hour),
      weekend_price_per_hour: values.weekend_price_per_hour ? Number(values.weekend_price_per_hour) : undefined,
      open_time: values.open_time,
      close_time: values.close_time,
      slot_duration_minutes: Number(values.slot_duration_minutes),
      peak_hours_start: values.peak_hours_start || undefined,
      peak_hours_end: values.peak_hours_end || undefined,
      peak_price_multiplier: Number(values.peak_price_multiplier),
      amenities: parseAmenities(values.amenities),
    };

    try {
      if (mode === 'create') {
        const created = await createGround.mutateAsync(payload);
        navigate(`/owner/grounds/${created.id}`);
      } else if (ground) {
        await updateGround.mutateAsync(payload);
        navigate('/owner/grounds');
      }
    } catch (submitError) {
      const message = submitError instanceof Error ? submitError.message : 'Failed to save ground.';
      setError(message);
    }
  };

  return (
    <Card className="max-w-3xl mx-auto">
      <CardHeader>
        <CardTitle>{mode === 'create' ? 'Add Ground' : 'Edit Ground'}</CardTitle>
      </CardHeader>
      <CardContent>
        <form className="space-y-4" onSubmit={handleSubmit}>
          {error && <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">{error}</p>}
          <div className="grid gap-4 md:grid-cols-2">
            <Input label="Ground name" value={values.name} onChange={(e) => setField('name', e.target.value)} required />
            <div>
              <Label htmlFor="ground_type">Ground type</Label>
              <select
                id="ground_type"
                className="mt-1 h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                value={values.ground_type}
                onChange={(e) => setField('ground_type', e.target.value as GroundFormValues['ground_type'])}
              >
                <option value="outdoor">Outdoor</option>
                <option value="indoor">Indoor</option>
                <option value="hybrid">Hybrid</option>
              </select>
            </div>
            <Input label="Location" value={values.location} onChange={(e) => setField('location', e.target.value)} required />
            <Input label="Price per hour" type="number" value={values.price_per_hour} onChange={(e) => setField('price_per_hour', e.target.value)} min="1" step="1" required />
            <Input label="Weekend price per hour" type="number" value={values.weekend_price_per_hour} onChange={(e) => setField('weekend_price_per_hour', e.target.value)} min="1" step="1" />
            <Input label="Slot duration (minutes)" type="number" value={values.slot_duration_minutes} onChange={(e) => setField('slot_duration_minutes', e.target.value)} min="30" step="15" required />
            <Input label="Open time" type="time" value={values.open_time} onChange={(e) => setField('open_time', e.target.value)} required />
            <Input label="Close time" type="time" value={values.close_time} onChange={(e) => setField('close_time', e.target.value)} required />
            <Input label="Peak hours start" type="time" value={values.peak_hours_start} onChange={(e) => setField('peak_hours_start', e.target.value)} />
            <Input label="Peak hours end" type="time" value={values.peak_hours_end} onChange={(e) => setField('peak_hours_end', e.target.value)} />
            <Input label="Peak price multiplier" type="number" value={values.peak_price_multiplier} onChange={(e) => setField('peak_price_multiplier', e.target.value)} min="1" max="3" step="0.1" />
          </div>

          <div>
            <Label htmlFor="description">Description</Label>
            <textarea
              id="description"
              className="mt-1 min-h-24 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              value={values.description}
              onChange={(e) => setField('description', e.target.value)}
            />
          </div>

          <div>
            <Label htmlFor="amenities">Amenities JSON</Label>
            <textarea
              id="amenities"
              className="mt-1 min-h-32 w-full rounded-md border border-input bg-background px-3 py-2 font-mono text-sm"
              value={values.amenities}
              onChange={(e) => setField('amenities', e.target.value)}
            />
          </div>

          <div className="flex justify-end gap-3">
            <Button type="button" variant="outline" onClick={() => navigate('/owner/grounds')}>
              Cancel
            </Button>
            <Button type="submit" className="bg-green-600 hover:bg-green-700" disabled={isSubmitting}>
              {isSubmitting ? 'Saving...' : mode === 'create' ? 'Create Ground' : 'Save Changes'}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
