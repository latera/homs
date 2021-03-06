import React, { useEffect, useState } from 'react';
import cn from 'classnames';
import compose from 'shared/utils/compose';
import { withConditions, withErrorBoundary } from 'shared/hoc';

type Props = {
  value?: string,
  name: string,
  hidden: boolean,
  disabled: boolean,
  params: {
    name: string,
    label: string,
    css_class?: string,
    label_css?: string,
    description: {
      placement: 'top' | 'bottom',
      text: string
    }
  },
  task: {
    key: string,
    process_key: string
  },
  env: {
    bpTranslator: (key: string, vars: Record<string, string>, fallback: string) => string
  },
  onRef: (obj: { serialize: () => Record<string, string> | null }) => void
}

type Link = {
  name: string,
  url: string,
  deleted: boolean
}

const HBWFormFileList: React.FC<Props> = ({
  value,
  name,
  params,
  hidden,
  disabled,
  task,
  env,
  onRef
}) => {
  const [links, setLinks] = useState<Link[]>((value && JSON.parse(value)) || []);

  const serialize = () => {
    if (disabled || hidden) {
      return null;
    } else {
      return { [params.name]: JSON.stringify(links.filter(link => !link.deleted)) };
    }
  };

  useEffect(() => {
    onRef({ serialize });

    return () => {
      onRef({ serialize: () => null });
    };
  }, [links, disabled, hidden]);

  const renderDescription = () => {
    const { placement, text } = params.description;

    return <div className="description" data-test={`description-${placement}`}>{text}</div>;
  };

  const toggleLink = (link: Link) => {
    const linkIndex = links.indexOf(link);

    setLinks(Object.assign([], links, { [linkIndex]: { ...link, deleted: !link.deleted } }));
  };

  const renderLink = (link: Link, key: number) => (
    <li className={cn({ danger: link.deleted })} key={key}>
      <a href={link.url}>{link.name}</a>
      &nbsp;
      {!disabled && (
        <a
          href="#"
          className={cn('fas', link.deleted ? 'fa-reply' : 'fa-times')}
          onClick={() => toggleLink(link)}
        />
      )}
    </li>
  );

  const renderLinks = (ls: Link[]) => ls.map((link, i) => renderLink(link, i));

  const cssClass = cn(params.css_class, 'hbw-file-list', { hidden });
  const label = env.bpTranslator(`${task.process_key}.${task.key}.${name}`, {}, params.label);
  const labelCSS = cn('hbw-file-list-label', params.label_css);
  const hiddenValue = JSON.stringify(links.filter(link => !link.deleted));

  return <div className={cssClass}>
    <div className="form-group">
      <input name={params.name} value={hiddenValue} type="hidden" />
      <label className={labelCSS}>
        <span>{` ${label}`}</span>
        {params.description?.placement === 'top' && renderDescription()}
        <ul>
          {renderLinks(links)}
        </ul>
      </label>
    </div>
  </div>;
};

export default compose(withConditions, withErrorBoundary)(HBWFormFileList);
