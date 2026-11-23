(() => {
  const splash = document.getElementById('kantin-launch');

  window.addEventListener('flutter-first-frame', () => splash.remove(), { once: true });

  window.addEventListener('error', (event) => {
    if (event.target?.id !== 'kantin-bootstrap') return;
    const message = document.createElement('p');
    message.textContent = 'Kantin Cerdas gagal dimuat. Muat ulang halaman.';
    splash.setAttribute('aria-label', message.textContent);
    splash.appendChild(message);
  }, true);
})();
