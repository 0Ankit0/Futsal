// Notification module types

export type NotificationType = 'info' | 'success' | 'warning' | 'error';

export interface Notification {
  id: number;
  user_id: number;
  title: string;
  body: string;
  type: NotificationType;
  is_read: boolean;
  extra_data?: unknown;
  created_at: string;
}

export interface NotificationList {
  items: Notification[];
  total: number;
  unread_count: number;
}

export interface NotificationPreference {
  id: number;
  user_id: number;
  websocket_enabled: boolean;
  email_enabled: boolean;
  push_enabled: boolean;
  sms_enabled: boolean;
  push_endpoint?: string;
}

export interface NotificationPreferenceUpdate {
  websocket_enabled?: boolean;
  email_enabled?: boolean;
  push_enabled?: boolean;
  sms_enabled?: boolean;
}
