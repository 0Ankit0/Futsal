import { forwardRef } from 'react';

type NextImageProps = React.ImgHTMLAttributes<HTMLImageElement> & {
  fill?: boolean;
  priority?: boolean;
};

const Image = forwardRef<HTMLImageElement, NextImageProps>(function Image(
  { alt, fill, style, ...rest },
  ref
) {
  const mergedStyle = fill
    ? {
        position: 'absolute' as const,
        inset: 0,
        width: '100%',
        height: '100%',
        objectFit: rest.objectFit,
        ...style,
      }
    : style;

  return <img ref={ref} alt={alt ?? ''} style={mergedStyle} {...rest} />;
});

export default Image;
