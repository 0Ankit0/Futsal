'use client';

import { AvatarForm } from '@/components/auth/avatar-form';
import { EditProfileForm } from '@/components/auth/edit-profile-form';
import { ChangePasswordForm } from '@/components/auth/change-password-form';

export default function ProfilePage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Profile</h1>
        <p className="text-gray-500">Manage your account and security settings.</p>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        <div className="space-y-6">
          <AvatarForm />
          <EditProfileForm />
        </div>
        <div className="space-y-6">
          <ChangePasswordForm />
        </div>
      </div>
    </div>
  );
}
