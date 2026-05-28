import { forwardRef } from 'react';
import { Link, type LinkProps } from 'react-router-dom';

type Href = string | { pathname?: string; search?: string; hash?: string };

type NextLikeLinkProps = Omit<
  React.AnchorHTMLAttributes<HTMLAnchorElement>,
  'href'
> & {
  href: Href;
  prefetch?: boolean;
  replace?: boolean;
  scroll?: boolean;
};

function hrefToTo(href: Href): LinkProps['to'] {
  if (typeof href === 'string') {
    return href;
  }

  return {
    pathname: href.pathname,
    search: href.search,
    hash: href.hash,
  };
}

const NextLink = forwardRef<HTMLAnchorElement, NextLikeLinkProps>(function NextLink(
  { href, replace, children, ...rest },
  ref
) {
  return (
    <Link ref={ref} to={hrefToTo(href)} replace={replace} {...rest}>
      {children}
    </Link>
  );
});

export default NextLink;
