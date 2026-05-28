type FontOptions = {
  variable?: string;
};

type FontResult = {
  variable: string;
  className: string;
};

function createFont(options?: FontOptions): FontResult {
  return {
    variable: options?.variable ?? '',
    className: '',
  };
}

export const Geist = createFont;
export const Geist_Mono = createFont;
