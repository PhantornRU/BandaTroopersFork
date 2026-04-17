import { createElement } from 'react';
import { createRoot } from 'react-dom/client';
import { act } from 'react-dom/test-utils';

import { Collapsible } from './Collapsible';

beforeAll(() => {
  (
    globalThis as typeof globalThis & {
      IS_REACT_ACT_ENVIRONMENT?: boolean;
    }
  ).IS_REACT_ACT_ENVIRONMENT = true;
});

afterAll(() => {
  delete (
    globalThis as typeof globalThis & {
      IS_REACT_ACT_ENVIRONMENT?: boolean;
    }
  ).IS_REACT_ACT_ENVIRONMENT;
});

describe('Collapsible', () => {
  it('does not render a stray numeric zero when open receives falsy non-boolean data', () => {
    const container = document.createElement('div');
    document.body.appendChild(container);
    const root = createRoot(container);

    act(() => {
      root.render(
        createElement(
          Collapsible,
          {
            title: 'Extra',
            open: 0 as unknown as boolean,
          },
          createElement('span', null, 'Body'),
        ),
      );
    });

    expect(container.textContent).toContain('Extra');
    expect(container.textContent).not.toContain('0');
    expect(container.textContent).not.toContain('Body');

    act(() => {
      root.unmount();
    });
    container.remove();
  });
});
