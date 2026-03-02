import Link from 'next/link';
import { MapPin, Clock, Shield, ArrowRight, CheckCircle } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';

export default function HomePage() {
  return (
    <main className="flex flex-col min-h-screen">
      {/* Hero */}
      <section className="relative bg-gradient-to-br from-green-600 to-green-800 text-white py-24 px-4">
        <div className="max-w-4xl mx-auto text-center">
          <h1 className="text-4xl md:text-6xl font-bold mb-6 leading-tight">
            Book Your Futsal Ground Instantly
          </h1>
          <p className="text-lg md:text-xl text-green-100 mb-10 max-w-2xl mx-auto">
            Find and reserve the best futsal grounds near you in seconds. Real-time availability, secure payments.
          </p>
          <Link
            href="/grounds"
            className="inline-flex items-center justify-center font-semibold rounded-lg transition-colors bg-white text-green-700 hover:bg-green-50 text-base px-8 py-3 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-white"
          >
            Browse Grounds <ArrowRight className="ml-2 h-5 w-5" />
          </Link>
        </div>
      </section>

      {/* Stats */}
      <section className="bg-green-700 text-white py-8 px-4">
        <div className="max-w-4xl mx-auto grid grid-cols-3 gap-4 text-center">
          {[
            { value: '500+', label: 'Bookings' },
            { value: '50+', label: 'Grounds' },
            { value: '100%', label: 'Secure Payments' },
          ].map(({ value, label }) => (
            <div key={label}>
              <p className="text-3xl font-bold">{value}</p>
              <p className="text-green-200 text-sm mt-1">{label}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Features */}
      <section className="py-20 px-4 bg-white">
        <div className="max-w-5xl mx-auto">
          <h2 className="text-3xl font-bold text-center text-gray-900 mb-12">Why Choose Us?</h2>
          <div className="grid md:grid-cols-3 gap-8">
            {[
              {
                icon: <MapPin className="h-8 w-8 text-green-600" />,
                title: 'Find Nearby Grounds',
                desc: 'Discover futsal grounds close to you with detailed location info and maps.',
              },
              {
                icon: <Clock className="h-8 w-8 text-green-600" />,
                title: 'Real-Time Availability',
                desc: 'See live slot availability and book instantly. No double bookings, ever.',
              },
              {
                icon: <Shield className="h-8 w-8 text-green-600" />,
                title: 'Secure Payments',
                desc: 'Pay safely via Khalti or eSewa. Your transactions are fully encrypted.',
              },
            ].map(({ icon, title, desc }) => (
              <Card key={title} className="text-center p-6 hover:shadow-lg transition-shadow">
                <CardContent className="pt-4">
                  <div className="flex justify-center mb-4">{icon}</div>
                  <h3 className="text-xl font-semibold text-gray-900 mb-2">{title}</h3>
                  <p className="text-gray-500 text-sm">{desc}</p>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* How it works */}
      <section className="py-20 px-4 bg-gray-50">
        <div className="max-w-4xl mx-auto">
          <h2 className="text-3xl font-bold text-center text-gray-900 mb-14">How It Works</h2>
          <div className="grid md:grid-cols-3 gap-8 relative">
            {[
              { step: 1, title: 'Browse Grounds', desc: 'Search and filter futsal grounds by location, type, and price.' },
              { step: 2, title: 'Pick a Slot', desc: 'Choose your preferred date and time from available slots.' },
              { step: 3, title: 'Play!', desc: 'Make a secure payment and show your QR code at the ground.' },
            ].map(({ step, title, desc }) => (
              <div key={step} className="flex flex-col items-center text-center">
                <div className="w-14 h-14 rounded-full bg-green-600 text-white flex items-center justify-center text-xl font-bold mb-4 shadow-md">
                  {step}
                </div>
                <h3 className="text-lg font-semibold text-gray-900 mb-2">{title}</h3>
                <p className="text-gray-500 text-sm">{desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Bottom CTA */}
      <section className="py-20 px-4 bg-green-600 text-white text-center">
        <div className="max-w-2xl mx-auto">
          <CheckCircle className="h-14 w-14 mx-auto mb-4 text-green-200" />
          <h2 className="text-3xl font-bold mb-4">Ready to Play?</h2>
          <p className="text-green-100 mb-8 text-lg">Find your perfect ground and book your next game today.</p>
        <Link
            href="/grounds"
            className="inline-flex items-center justify-center font-semibold rounded-lg transition-colors bg-white text-green-700 hover:bg-green-50 px-8 py-3 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-white"
          >
            Find a Ground
          </Link>
        </div>
      </section>
    </main>
  );
}
