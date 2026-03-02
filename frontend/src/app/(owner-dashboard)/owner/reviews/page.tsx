'use client';

import { useState } from 'react';
import { useGrounds, useGroundReviews, useReplyToReview } from '@/hooks/use-futsal';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Star } from 'lucide-react';

function StarRating({ rating }: { rating: number }) {
  return (
    <div className="flex gap-0.5">
      {[1, 2, 3, 4, 5].map((s) => (
        <Star key={s} className={`h-4 w-4 ${s <= rating ? 'text-yellow-400 fill-yellow-400' : 'text-gray-300'}`} />
      ))}
    </div>
  );
}

export default function OwnerReviewsPage() {
  const { data: grounds = [] } = useGrounds();
  const [selectedGroundId, setSelectedGroundId] = useState<number | null>(null);
  const groundId = selectedGroundId ?? grounds[0]?.id ?? 0;
  const { data: reviews = [], isLoading } = useGroundReviews(groundId);
  const { mutate: reply, isPending } = useReplyToReview();
  const [replyText, setReplyText] = useState<Record<number, string>>({});
  const [replyingTo, setReplyingTo] = useState<number | null>(null);

  const avgRating = reviews.length
    ? (reviews.reduce((s, r) => s + r.rating, 0) / reviews.length).toFixed(1)
    : '—';

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Reviews</h1>

      <div className="flex gap-4 items-center">
        <select
          className="border rounded-lg px-3 py-2 text-sm"
          value={selectedGroundId ?? ''}
          onChange={(e) => setSelectedGroundId(e.target.value ? Number(e.target.value) : null)}
        >
          {grounds.map((g) => (
            <option key={g.id} value={g.id}>{g.name}</option>
          ))}
        </select>
        <span className="text-sm text-gray-500">
          {reviews.length} review{reviews.length !== 1 ? 's' : ''} · Avg: ⭐ {avgRating}
        </span>
      </div>

      {isLoading ? (
        <p className="text-gray-400">Loading reviews...</p>
      ) : reviews.length === 0 ? (
        <p className="text-gray-400">No reviews yet for this ground.</p>
      ) : (
        <div className="space-y-4">
          {reviews.map((r) => (
            <Card key={r.id}>
              <CardContent className="p-5 space-y-3">
                <div className="flex items-start justify-between">
                  <div className="space-y-1">
                    <StarRating rating={r.rating} />
                    <p className="text-sm text-gray-700">{r.comment || 'No comment.'}</p>
                  </div>
                  <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                    r.is_verified ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'
                  }`}>
                    {r.is_verified ? 'Verified Player' : 'Unverified'}
                  </span>
                </div>

                {r.owner_reply ? (
                  <div className="bg-green-50 rounded-lg p-3">
                    <p className="text-xs font-medium text-green-700">Your reply:</p>
                    <p className="text-sm text-gray-700 mt-1">{r.owner_reply}</p>
                  </div>
                ) : (
                  <>
                    {replyingTo === r.id ? (
                      <div className="space-y-2">
                        <textarea
                          className="w-full border rounded-lg px-3 py-2 text-sm resize-none"
                          rows={3}
                          placeholder="Write your reply..."
                          value={replyText[r.id] ?? ''}
                          onChange={(e) => setReplyText({ ...replyText, [r.id]: e.target.value })}
                        />
                        <div className="flex gap-2">
                          <Button
                            size="sm"
                            className="bg-green-600 hover:bg-green-700"
                            disabled={isPending || !replyText[r.id]?.trim()}
                            onClick={() => {
                              reply({ reviewId: r.id, reply: replyText[r.id] }, {
                                onSuccess: () => setReplyingTo(null),
                              });
                            }}
                          >
                            Submit Reply
                          </Button>
                          <Button size="sm" variant="outline" onClick={() => setReplyingTo(null)}>
                            Cancel
                          </Button>
                        </div>
                      </div>
                    ) : (
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => setReplyingTo(r.id)}
                      >
                        Reply to Review
                      </Button>
                    )}
                  </>
                )}
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
