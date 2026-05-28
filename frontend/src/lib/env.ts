function fromMetaEnv(key: string): string | undefined {
  const metaEnv = (import.meta as ImportMeta & { env?: Record<string, string | undefined> }).env;
  return metaEnv?.[key];
}

function fromProcessEnv(key: string): string | undefined {
  if (typeof process === 'undefined') return undefined;
  const proc = process as unknown as { env?: Record<string, string | undefined> };
  return proc.env?.[key];
}

export function getEnv(...keys: string[]): string | undefined {
  for (const key of keys) {
    const value = fromMetaEnv(key) ?? fromProcessEnv(key);
    if (value) return value;
  }
  return undefined;
}
