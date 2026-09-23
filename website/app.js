const buttons = [...document.querySelectorAll('[data-action]')];
const preview = document.querySelector('.demo-window');
const previewLabel = document.querySelector('#preview-label');

for (const button of buttons) {
  button.addEventListener('click', () => {
    preview.dataset.layout = button.dataset.action;
    previewLabel.textContent = button.querySelector('span').textContent;
    for (const other of buttons) other.setAttribute('aria-pressed', String(other === button));
  });
}

// Enable downloads only when a specific public release has been configured.
// No GitHub API request or third-party script is needed to load this page.
async function loadRelease() {
  try {
    const response = await fetch('./release.json');
    if (!response.ok) return;
    const release = await response.json();
    if (typeof release.version !== 'string' || !release.version || typeof release.url !== 'string') return;
    const url = new URL(release.url);
    if (url.protocol !== 'https:' || url.hostname !== 'github.com' ||
        !url.pathname.startsWith('/ilyakamens/windower/releases/download/')) return;
    const download = document.querySelector('#download');
    download.href = url.href;
    download.removeAttribute('aria-disabled');
    download.removeAttribute('tabindex');
    document.querySelector('#release-status').textContent = `Version ${release.version}`;
  } catch {
    // The source link and accurate unavailable state remain usable offline.
  }
}
loadRelease();
