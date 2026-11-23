(() => {
  'use strict';
  const redirect = new URL(window.location.href);
  const states = redirect.searchParams.getAll('kc_state');
  window.history.replaceState(null, '', redirect.pathname);
  if (states.length !== 1 || !/^[A-Za-z0-9_-]{43}$/.test(states[0])) return;
  const channel = new BroadcastChannel('kc-google-' + states[0]);
  channel.postMessage(redirect.href);
  channel.close();
})();
